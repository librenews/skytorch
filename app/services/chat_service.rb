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
    
    # Extract rate limit information from response headers
    raw_response = response.instance_variable_get(:@raw)
    headers = raw_response.env.response_headers
    
    # Add assistant response to chat
    assistant_message = @chat.messages.create!(
      content: response.content,
      role: 'assistant'
    )
    
    # Return both the message and rate limit info
    {
      message: assistant_message,
      rate_limits: {
        remaining_requests: headers['x-ratelimit-remaining-requests'],
        limit_requests: headers['x-ratelimit-limit-requests'],
        remaining_tokens: headers['x-ratelimit-remaining-tokens'],
        limit_tokens: headers['x-ratelimit-limit-tokens']
      }
    }
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
