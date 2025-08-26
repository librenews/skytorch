class Tool < ApplicationRecord
  belongs_to :user
  
  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }
  validates :tool_type, presence: true, inclusion: { in: %w[tool resource prompt] }
  validates :visibility, presence: true, inclusion: { in: %w[public private unlisted] }
  validates :definition, presence: true
  validates :tags, length: { maximum: 20 }
  
  # Scopes
  scope :public_tools, -> { where(visibility: 'public') }
  scope :by_type, ->(type) { where(tool_type: type) }
  scope :by_user, ->(user) { where(user: user) }
  scope :searchable, -> { where(visibility: ['public', 'unlisted']) }
  scope :mcp_tools, -> { where(tool_type: 'tool') }
  
  # Search functionality
  def self.search(query, options = {})
    tools = searchable
    
    if query.present?
      # Search in name, description, and tags
      tools = tools.where(
        "name ILIKE :query OR description ILIKE :query OR tags::text ILIKE :query",
        query: "%#{query}%"
      )
    end
    
    # Filter by type
    tools = tools.by_type(options[:type]) if options[:type].present?
    
    # Filter by user
    tools = tools.by_user(options[:user]) if options[:user].present?
    
    # Order by relevance (could be enhanced with embeddings later)
    tools.order(created_at: :desc)
  end
  
  # Lexicon format methods
  def to_lexicon_record
    {
      "$type" => "social.tools.tool",
      "createdAt" => created_at.iso8601,
      "type" => tool_type,
      "owner" => user.bluesky_did,
      "name" => name,
      "description" => description,
      "tags" => tags,
      "definition" => definition,
      "visibility" => visibility
    }
  end
  
  def self.from_lexicon_record(record, user)
    new(
      user: user,
      name: record["name"],
      description: record["description"],
      tool_type: record["type"],
      visibility: record["visibility"],
      tags: record["tags"] || [],
      definition: record["definition"] || {}
    )
  end
  
  # MCP integration methods
  def to_mcp_tool
    {
      name: name,
      description: description,
      input_schema: definition["input_schema"] || {},
      transport: transport_type,
      command: command,
      args: args,
      env: env
    }
  end
  
  def self.from_mcp_tool(mcp_tool, user)
    new(
      user: user,
      name: mcp_tool[:name],
      description: mcp_tool[:description],
      tool_type: 'tool',
      visibility: 'private',
      tags: mcp_tool[:tags] || [],
      definition: {
        transport: mcp_tool[:transport] || 'stdio',
        command: mcp_tool[:command],
        args: mcp_tool[:args] || [],
        env: mcp_tool[:env] || {},
        input_schema: mcp_tool[:input_schema] || {}
      }
    )
  end
  
  # MCP definition helpers
  def transport_type
    definition["transport"] || "stdio"
  end
  
  def command
    definition["command"]
  end
  
  def args
    definition["args"] || []
  end
  
  def env
    definition["env"] || {}
  end
  
  def input_schema
    definition["input_schema"] || {}
  end
  
  # Execute the MCP tool
  def execute(params = {})
    case transport_type
    when "stdio"
      execute_stdio_tool(params)
    when "http"
      execute_http_tool(params)
    else
      { error: "Unsupported transport type: #{transport_type}" }
    end
  end
  
  private
  
  def execute_stdio_tool(params)
    # This would integrate with the existing MCP infrastructure
    # For now, return a placeholder
    {
      tool_name: name,
      params: params,
      transport: transport_type,
      command: command,
      args: args
    }
  end
  
  def execute_http_tool(params)
    # HTTP-based MCP tool execution
    {
      tool_name: name,
      params: params,
      transport: transport_type,
      url: command # command field contains the URL for HTTP tools
    }
  end
  
  # Embedding support (placeholder for future implementation)
  def generate_embedding
    # TODO: Implement embedding generation
    # This would use a service like OpenAI's text-embedding-ada-002
    # to generate embeddings for name, description, and tags
  end
  
  def similarity_score(other_tool)
    # TODO: Implement similarity scoring using embeddings
    # This would calculate cosine similarity between embeddings
  end
end



