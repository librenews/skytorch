require 'ruby_llm'

class ChatService
  def initialize(provider = nil)
    @provider = provider || Provider.default_provider
    configure_provider
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
      
      # Generate response using ruby_llm directly
      llm_response = generate_llm_response(messages)
      
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
    messages = chat.messages.order(:created_at)
    return "New Chat" if messages.empty?
    
    message_count = messages.count
    
    if message_count == 1
      # First message - just truncate the user's message
      first_message = messages.first
      content = first_message.content
      if content.length > 50
        "#{content[0..47]}..."
      else
        content
      end
    elsif message_count == 4
      # 4th message (likely 2nd LLM response) - ask LLM to create a summary title
      begin
        # Get the conversation context for better title generation
        conversation_context = messages.limit(4).map do |msg|
          "#{msg.role}: #{msg.content}"
        end.join("\n")
        
        title_prompt = [
          {
            role: 'system',
            content: 'Generate a short, descriptive title (max 50 characters) for this chat conversation. Return only the title, nothing else.'
          },
          {
            role: 'user',
            content: "Based on this conversation:\n\n#{conversation_context}\n\nGenerate a short title:"
          }
        ]
        
        llm_response = generate_llm_response(title_prompt)
        title = llm_response['content'].strip
        
        # Update the chat title
        chat.update!(title: title) if title.present? && title.length <= 50
        
        title
      rescue => e
        Rails.logger.error "Error generating title with LLM: #{e.message}"
        # Fallback to first message content
        first_message = messages.first
        content = first_message.content
        if content.length > 50
          "#{content[0..47]}..."
        else
          content
        end
      end
    else
      # For other message counts, return the current title
      chat.title
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
      estimated_cost: 0 # TODO: Implement cost calculation
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
      estimated_cost: 0 # TODO: Implement cost calculation
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
      
      # Generate response using ruby_llm directly with tools
      llm_response = generate_llm_response_with_tools(messages, tools)
      
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

  private

  def configure_provider
    case @provider.provider_type
    when 'openai'
      RubyLLM.configure do |config|
        config.openai_api_key = @provider.api_key
      end
    when 'anthropic'
      RubyLLM.configure do |config|
        config.anthropic_api_key = @provider.api_key
      end
    when 'google'
      RubyLLM.configure do |config|
        config.gemini_api_key = @provider.api_key
      end
    end
  end

  def generate_llm_response(messages)
    # Get the last user message
    last_message = messages.last
    user_content = last_message[:content] || last_message['content']

    # Use the simple ruby_llm API - it handles all provider differences
    chat = RubyLLM.chat
    response = chat.ask(user_content)

    {
      'content' => response.content,
      'usage' => {
        'prompt_tokens' => response.input_tokens || 0,
        'completion_tokens' => response.output_tokens || 0,
        'total_tokens' => (response.input_tokens || 0) + (response.output_tokens || 0)
      }
    }
  rescue => e
    Rails.logger.error "LLM API error: #{e.message}"
    raise e
  end

  def generate_llm_response_with_tools(messages, tools)
    # Get the last user message
    last_message = messages.last
    user_content = last_message[:content] || last_message['content']

    # Use the simple ruby_llm API with tools
    chat = RubyLLM.chat
    response = chat.ask(user_content)

    {
      'content' => response.content,
      'tool_calls' => response.tool_calls || [],
      'usage' => {
        'prompt_tokens' => response.input_tokens || 0,
        'completion_tokens' => response.output_tokens || 0,
        'total_tokens' => (response.input_tokens || 0) + (response.output_tokens || 0)
      }
    }
  rescue => e
    Rails.logger.error "LLM API error with tools: #{e.message}"
    raise e
  end
end
