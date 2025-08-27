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
    # 3. Return the response
    
    messages = chat.messages.order(:created_at)
    
    # Simple mock response for now
    case @provider.provider_type
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
end
