class GlobalMcpServer < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :transport_type, presence: true, inclusion: { in: %w[stdio streamable sse] }
  validates :config, presence: true
  
  scope :active, -> { where(is_active: true) }
  
  def self.default_servers
    [
      {
        name: 'filesystem',
        transport_type: 'stdio',
        config: {
          command: 'npx',
          args: ['@modelcontextprotocol/server-filesystem', '/private/tmp'],
          env: { 'NODE_ENV' => 'production' }
        },
        is_active: true
      }
    ]
  end
end
