require 'ruby_llm'

class ChatService
  def initialize(provider = nil)
    @provider = provider || Provider.default_provider
    @llm_client = LlmClientService.new(@provider)
  end

  def generate_response(chat, user_message)
    begin
      # Get chat history for context
      messages = chat.messages.order(:created_at).map do |msg|
        {
          role: msg.role,
          content: msg.content
        }
      end
      
      # Add the new user message
      messages << {
        role: 'user',
        content: user_message
      }
      
      # Generate response using the LLM client
      llm_response = @llm_client.generate_response(messages)
      
      # Extract usage data using the service
      usage_data = UsageTrackerService.extract_usage(@provider.provider_type, llm_response)
      
      # Create the assistant message with usage data
      assistant_message = chat.messages.create!(
        content: llm_response['content'],
        role: 'assistant',
        prompt_tokens: usage_data.prompt_tokens,
        completion_tokens: usage_data.completion_tokens,
        total_tokens: usage_data.total_tokens,
        usage_data: usage_data.raw_data
      )
      
      {
        message: assistant_message,
        usage: usage_data,
        cost: UsageTrackerService.calculate_cost(usage_data, @provider.provider_type, @provider.default_model)
      }
    rescue => e
      Rails.logger.error "Error generating response: #{e.message}"
      
      # Create a system message for the error
      system_message = chat.messages.create!(
        content: "⚠️ Unable to generate a response at this time. Please try again later.",
        role: 'system'
      )
      
      {
        message: system_message,
        error: true
      }
    end
  end

  def generate_title(chat)
    # Generate a title based on the first few messages
    first_message = chat.messages.order(:created_at).first
    return "New Chat" unless first_message
    
    begin
      # Use LLM to generate a better title
      title_prompt = [
        {
          role: 'system',
          content: 'Generate a short, descriptive title (max 50 characters) for this chat based on the first message. Return only the title, nothing else.'
        },
        {
          role: 'user',
          content: first_message.content
        }
      ]
      
      llm_response = @llm_client.generate_response(title_prompt)
      title = llm_response['content'].strip
      
      # Fallback if LLM fails or returns something too long
      if title.length > 50 || title.blank?
        content = first_message.content
        if content.length > 50
          "#{content[0..47]}..."
        else
          content
        end
      else
        title
      end
    rescue => e
      Rails.logger.error "Error generating title with LLM: #{e.message}"
      # Fallback to simple title generation
      content = first_message.content
      if content.length > 50
        "#{content[0..47]}..."
      else
        content
      end
    end
  end

  def self.create_chat_for_user(user, title = nil)
    chat = user.chats.create!(
      title: title || "New Chat",
      status: 'active'
    )
    
    # Add a welcome message
    chat.messages.create!(
      content: "Hello! I'm your AI assistant. How can I help you today?",
      role: 'assistant'
    )
    
    chat
  end

  def self.archive_chat(chat)
    chat.update!(status: 'archived')
  end

  def self.report_chat(chat)
    chat.update!(status: 'reported')
  end

  def self.delete_chat(chat)
    chat.destroy
  end
  
  # Usage aggregation methods
  def self.get_chat_usage(chat)
    messages = chat.messages.assistant_messages.with_usage
    
    {
      total_messages: messages.count,
      total_tokens: messages.sum(:total_tokens),
      prompt_tokens: messages.sum(:prompt_tokens),
      completion_tokens: messages.sum(:completion_tokens),
      estimated_cost: messages.sum { |m| m.cost_estimate }
    }
  end
  
  def self.get_user_usage(user, time_period = nil)
    scope = user.chats.joins(:messages).where(messages: { role: :assistant })
    scope = scope.where('messages.created_at >= ?', time_period) if time_period
    
    messages = scope.select('messages.*')
    
    {
      total_chats: user.chats.count,
      total_messages: messages.count,
      total_tokens: messages.sum(:total_tokens),
      prompt_tokens: messages.sum(:prompt_tokens),
      completion_tokens: messages.sum(:completion_tokens),
      estimated_cost: messages.sum { |m| m.cost_estimate }
    }
  end

  # Method ready for MCP tool integration
  def generate_response_with_tools(chat, user_message, tools = [])
    begin
      # Get chat history for context
      messages = chat.messages.order(:created_at).map do |msg|
        {
          role: msg.role,
          content: msg.content
        }
      end
      
      # Add the new user message
      messages << {
        role: 'user',
        content: user_message
      }
      
      # Generate response using the LLM client with tools
      llm_response = @llm_client.generate_response_with_tools(messages, tools)
      
      # Extract usage data using the service
      usage_data = UsageTrackerService.extract_usage(@provider.provider_type, llm_response)
      
      # Create the assistant message with usage data
      assistant_message = chat.messages.create!(
        content: llm_response['content'],
        role: 'assistant',
        prompt_tokens: usage_data.prompt_tokens,
        completion_tokens: usage_data.completion_tokens,
        total_tokens: usage_data.total_tokens,
        usage_data: usage_data.raw_data
      )
      
      {
        message: assistant_message,
        usage: usage_data,
        cost: UsageTrackerService.calculate_cost(usage_data, @provider.provider_type, @provider.default_model),
        tool_calls: llm_response['tool_calls'] || []
      }
    rescue => e
      Rails.logger.error "Error generating response with tools: #{e.message}"
      
      # Create a system message for the error
      system_message = chat.messages.create!(
        content: "⚠️ Unable to generate a response at this time. Please try again later.",
        role: 'system'
      )
      
      {
        message: system_message,
        error: true
      }
    end
  end
end
