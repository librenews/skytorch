class LlmProviderService
  def self.create_openai_provider(api_key, model = "gpt-4o-mini")
    LlmProvider.create!(
      name: "OpenAI",
      provider_type: "openai",
      api_key: api_key,
      base_url: "https://api.openai.com/v1",
      default_model: model,
      is_active: true
    )
  end
  
  def self.create_anthropic_provider(api_key, model = "claude-3-5-sonnet-20241022")
    LlmProvider.create!(
      name: "Anthropic Claude",
      provider_type: "anthropic",
      api_key: api_key,
      base_url: "https://api.anthropic.com",
      default_model: model,
      is_active: true
    )
  end
  
  def self.create_google_provider(api_key, model = "gemini-1.5-flash")
    LlmProvider.create!(
      name: "Google Gemini",
      provider_type: "google",
      api_key: api_key,
      base_url: "https://generativelanguage.googleapis.com",
      default_model: model,
      is_active: true
    )
  end
  
  def self.create_mock_provider
    LlmProvider.create!(
      name: "Mock Provider",
      provider_type: "mock",
      api_key: "mock_key",
      base_url: nil,
      default_model: "mock-model",
      is_active: true
    )
  end
  
  def self.available_providers
    LlmProvider.active.order(:name)
  end
  
  def self.set_default_provider(provider_id)
    # Deactivate all providers
    LlmProvider.update_all(is_active: false)
    
    # Activate the selected provider
    provider = LlmProvider.find(provider_id)
    provider.update!(is_active: true)
    
    provider
  end
end
