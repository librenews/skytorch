require 'ruby_llm'

# Configure RubyLLM once at application startup
RubyLLM.configure do |config|
  # Use Rails logger
  config.logger = Rails.logger
  
  # Environment-specific settings
  config.request_timeout = Rails.env.production? ? 120 : 30
  config.log_level = Rails.env.production? ? :info : :debug
  
  # Default models
  config.default_model = 'gpt-4o-mini'
end

# Configure providers from database on application startup
Rails.application.config.after_initialize do
  begin
    # Get the default provider from database
    default_provider = Provider.default_provider
    
    if default_provider
      case default_provider.provider_type
      when 'openai'
        RubyLLM.configure do |config|
          config.openai_api_key = default_provider.api_key
          config.default_model = default_provider.default_model
        end
      when 'anthropic'
        RubyLLM.configure do |config|
          config.anthropic_api_key = default_provider.api_key
          config.default_model = default_provider.default_model
        end
      when 'google'
        RubyLLM.configure do |config|
          config.gemini_api_key = default_provider.api_key
          config.default_model = default_provider.default_model
        end
      when 'mock'
        raise "Mock providers are not supported with RubyLLM. Please use a real provider (openai, anthropic, or google)."
      end
      
      Rails.logger.info "RubyLLM configured with #{default_provider.provider_type} provider"
    else
      Rails.logger.warn "No default provider found in database"
    end
  rescue => e
    Rails.logger.error "Error configuring RubyLLM: #{e.message}"
  end
end
