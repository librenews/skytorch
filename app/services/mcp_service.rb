class McpService
  # Example method to create an MCP client for a file system server
  def self.create_file_system_client
    RubyLLM::MCP.client(
      name: "file-system",
      transport_type: :stdio,
      config: {
        command: "npx",
        args: ["@modelcontextprotocol/server-filesystem", "/path/to/your/project"],
        env: { "NODE_ENV" => "production" }
      }
    )
  end

  # Example method to create an MCP client for a web search server
  def self.create_web_search_client
    RubyLLM::MCP.client(
      name: "web-search",
      transport_type: :streamable,
      config: {
        url: "http://localhost:8080/mcp",
        headers: { "Authorization" => "Bearer your-search-api-token" }
      }
    )
  end

  # Example method to create an MCP client for a database server
  def self.create_database_client
    RubyLLM::MCP.client(
      name: "database",
      transport_type: :sse,
      config: {
        url: "http://localhost:9292/mcp/sse"
      }
    )
  end

  # Helper method to get available tools from an MCP client
  def self.list_available_tools(client)
    return [] unless client

    tools = client.tools
    tools.map do |tool|
      {
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters
      }
    end
  end

  # Helper method to get available resources from an MCP client
  def self.list_available_resources(client)
    return [] unless client

    resources = client.resources
    resources.map do |resource|
      {
        name: resource.name,
        description: resource.description,
        mime_type: resource.mime_type
      }
    end
  end

  # Helper method to get available prompts from an MCP client
  def self.list_available_prompts(client)
    return [] unless client

    prompts = client.prompts
    prompts.map do |prompt|
      {
        name: prompt.name,
        description: prompt.description,
        arguments: prompt.arguments.map { |arg| { name: arg.name, description: arg.description, required: arg.required } }
      }
    end
  end

  # Example usage method
  def self.example_usage_with_chat_service
    # Create an MCP client
    mcp_client = create_file_system_client
    
    # Get a chat (you would normally get this from your application)
    chat = Chat.first
    
    # Use ChatService with MCP client
    result = ChatService.generate_response(
      chat, 
      "Can you help me find all Ruby files in my project?", 
      mcp_client
    )
    
    puts "Response: #{result[:message].content}"
    puts "Success: #{result[:success]}"
  end
end
