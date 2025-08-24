class LlmProvider < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :provider_type, presence: true, inclusion: { in: %w[openai anthropic google gemini mock] }
  validates :api_key, presence: true
  validates :default_model, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  
  # Encrypt API keys for security (temporarily disabled)
  # encrypts :api_key
  
  scope :active, -> { where(is_active: true) }
  scope :global, -> { where(user_id: nil) }
  scope :user_owned, -> { where.not(user_id: nil) }
  
  def self.default_provider
    active.first
  end

  def self.global_default
    global.active.first
  end

  def self.default_provider_for_user(user)
    user&.default_provider || global_default
  end

  def global?
    user_id.nil?
  end

  def user_owned?
    user_id.present?
  end

  def owner_name
    user_owned? ? user.display_name : "Global"
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
