# Configure ruby_llm
RubyLLM.configure do |config|
  # You can configure different providers here
  # For example, to use OpenAI:
  # config.provider = :openai
  # config.api_key = ENV['OPENAI_API_KEY']
  
  # For now, we'll use a mock provider for development
  # Note: The provider is set when creating the client, not in global config
end
