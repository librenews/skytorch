require 'ruby_llm'

class ChatService
  def initialize(chat, provider = nil)
    @chat = chat
    @provider = provider || LlmProvider.default_provider
    configure_llm
  end
  
  def send_message(content)
    # Add the user message to the LLM chat context
    @llm.add_message(role: 'user', content: content)
    
    # Generate response using LLM
    response = @llm.complete
    
    # Add assistant response to chat
    assistant_message = @chat.messages.create!(
      content: response.content,
      role: 'assistant'
    )
    
    assistant_message
  end
  
  private
  
  def configure_llm
    if @provider
      # Configure ruby_llm with the provider settings
      RubyLLM.configure do |config|
        case @provider.provider_type
        when 'openai'
          config.openai_api_key = @provider.api_key
          config.default_model = @provider.default_model if @provider.default_model.present?
        when 'anthropic'
          config.anthropic_api_key = @provider.api_key
          config.default_model = @provider.default_model if @provider.default_model.present?
        when 'google'
          config.gemini_api_key = @provider.api_key
          config.default_model = @provider.default_model if @provider.default_model.present?
        end
      end
      
      @llm = RubyLLM::Chat.new
    else
      # Fallback to mock provider if no provider is configured
      @llm = RubyLLM::Chat.new
    end
  end
end
