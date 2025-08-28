class Provider < ApplicationRecord
  belongs_to :user, optional: true
  
  validates :name, presence: true
  validates :provider_type, presence: true, inclusion: { in: %w[openai anthropic google] }
  validates :api_key, presence: true
  validates :base_url, presence: true, if: -> { provider_type == 'google' }
  validates :default_model, presence: true
  
  # encrypts :api_key
  
  scope :active, -> { where(is_active: true) }
  scope :global, -> { where(user_id: nil) }
  
  def self.global_default
    global.active.first
  end
  
  def self.default_provider
    active.first || global_default
  end
end
