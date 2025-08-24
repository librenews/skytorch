class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  
  validates :title, presence: true
  validates :user, presence: true
  
  scope :recent, -> { order(updated_at: :desc) }
  
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
