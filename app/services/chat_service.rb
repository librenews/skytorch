require 'ruby_llm'

class ChatService
  def initialize(provider = nil)
    @provider = provider || Provider.default_provider
  end

  def generate_response(chat, user_message)
    # This is a placeholder for the actual LLM integration
    # In a real implementation, you would:
    # 1. Get the chat history
    # 2. Send the message to the LLM provider
    # 3. Return the response with usage data
    
    begin
      messages = chat.messages.order(:created_at)
      
      # Simple mock response for now
      response_content = case @provider.provider_type
      when 'openai'
        "I'm an OpenAI-powered assistant. You said: '#{user_message}'. How can I help you further?"
      when 'anthropic'
        "I'm a Claude-powered assistant. You said: '#{user_message}'. How can I help you further?"
      when 'google'
        "I'm a Google Gemini-powered assistant. You said: '#{user_message}'. How can I help you further?"
      when 'mock'
        "I'm a mock assistant. You said: '#{user_message}'. This is a test response."
      else
        "I'm an AI assistant. You said: '#{user_message}'. How can I help you further?"
      end
      
      # Mock usage data
      mock_response = {
        'content' => response_content,
        'usage' => {
          'prompt_tokens' => user_message.length / 4 + 50, # Rough estimate
          'completion_tokens' => response_content.length / 4,
          'total_tokens' => (user_message.length + response_content.length) / 4 + 50
        }
      }
      
      # Extract usage data using the service
      usage_data = UsageTrackerService.extract_usage(@provider.provider_type, mock_response)
      
      # Create the assistant message with usage data
      assistant_message = chat.messages.create!(
        content: response_content,
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
    
    # Simple title generation - in a real app, you'd use the LLM
    content = first_message.content
    if content.length > 50
      "#{content[0..47]}..."
    else
      content
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
end
