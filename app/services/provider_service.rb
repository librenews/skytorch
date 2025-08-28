class ProviderService
  def self.create_openai_provider(api_key, model = "gpt-4o-mini")
    Provider.create!(
      name: "OpenAI",
      provider_type: "openai",
      api_key: api_key,
      default_model: model,
      is_active: true
    )
  end

  def self.create_anthropic_provider(api_key, model = "claude-3-5-sonnet-20241022")
    Provider.create!(
      name: "Anthropic",
      provider_type: "anthropic",
      api_key: api_key,
      default_model: model,
      is_active: true
    )
  end

  def self.create_google_provider(api_key, model = "gemini-1.5-flash")
    Provider.create!(
      name: "Google",
      provider_type: "google",
      api_key: api_key,
      base_url: "https://generativelanguage.googleapis.com",
      default_model: model,
      is_active: true
    )
  end

  def self.available_providers
    Provider.active.order(:name)
  end

  def self.set_default_provider(provider_id)
    Provider.update_all(is_active: false)
    provider = Provider.find(provider_id)
    provider.update!(is_active: true)
  end
end
