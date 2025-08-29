class UserMcpServer < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :transport_type, presence: true, inclusion: { in: %w[stdio streamable sse] }
  validates :config, presence: true
  
  scope :active, -> { where(is_active: true) }
end
