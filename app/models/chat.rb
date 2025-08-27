class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  
  validates :title, presence: true
  validates :user, presence: true
  validates :status, presence: true, inclusion: { in: %w[active archived reported] }
  
  enum :status, { active: 'active', archived: 'archived', reported: 'reported' }, default: 'active'
  
  scope :recent, -> { order(updated_at: :desc) }
  scope :active, -> { where(status: :active) }
  scope :archived, -> { where(status: :archived) }
  scope :reported, -> { where(status: :reported) }
  
  def message_count
    messages.count
  end
  
  def last_message
    messages.order(created_at: :desc).first
  end
  
  def last_message_time
    last_message&.created_at
  end
end
