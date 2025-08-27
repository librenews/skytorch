class Message < ApplicationRecord
  belongs_to :chat
  
  validates :content, presence: true
  
  enum :role, { user: 'user', assistant: 'assistant', system: 'system' }
  
  # Usage tracking fields
  validates :prompt_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :completion_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Store raw usage data from LLM providers
  validates :usage_data, presence: false
  
  scope :assistant_messages, -> { where(role: :assistant) }
  scope :with_usage, -> { where.not(total_tokens: nil) }
  
  def has_usage_data?
    total_tokens.present?
  end
  
  def cost_estimate(provider = nil)
    return 0 unless has_usage_data?
    
    # This would be calculated based on the provider's pricing
    # For now, return a placeholder
    total_tokens * 0.0001 # $0.0001 per token as example
  end
  
  def set_usage_data(usage_hash)
    self.prompt_tokens = usage_hash[:prompt_tokens]
    self.completion_tokens = usage_hash[:completion_tokens]
    self.total_tokens = usage_hash[:total_tokens]
    self.usage_data = usage_hash
  end
end
