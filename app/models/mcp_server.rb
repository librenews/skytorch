class McpServer < ApplicationRecord
  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::regexp }
end
