class LlmProvider < ApplicationRecord
  validates :name, presence: true
  validates :provider_type, presence: true, inclusion: { in: %w[openai anthropic google gemini mock] }
  validates :api_key, presence: true
  validates :default_model, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  
  # Encrypt API keys for security (temporarily disabled)
  # encrypts :api_key
  
  scope :active, -> { where(is_active: true) }
  
  def self.default_provider
    active.first
  end
  
  def provider_config
    {
      provider: provider_type.to_sym,
      api_key: api_key,
      base_url: base_url.presence,
      default_model: default_model
    }
  end
end
