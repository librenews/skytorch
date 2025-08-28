# MCP (Model Context Protocol) Integration

SkyTorch now supports MCP (Model Context Protocol) integration through the `ruby_llm-mcp` gem, allowing you to use MCP servers' tools, resources, and prompts in your chat conversations.

## Overview

MCP integration allows the LLM to:
- **Use tools** from MCP servers (file operations, web search, database queries, etc.)
- **Access resources** like files, data, and structured information
- **Use predefined prompts** with arguments for consistent interactions
- **Work with multiple MCP servers** simultaneously

## Basic Usage

### 1. Create an MCP Client

```ruby
# Example: File system MCP server
mcp_client = RubyLLM::MCP.client(
  name: "file-system",
  transport_type: :stdio,
  config: {
    command: "npx",
    args: ["@modelcontextprotocol/server-filesystem", "/path/to/your/project"],
    env: { "NODE_ENV" => "production" }
  }
)

# Example: Web search MCP server
mcp_client = RubyLLM::MCP.client(
  name: "web-search",
  transport_type: :streamable,
  config: {
    url: "http://localhost:8080/mcp",
    headers: { "Authorization" => "Bearer your-search-api-token" }
  }
)
```

### 2. Use MCP with ChatService

```ruby
# Get a chat instance
chat = Chat.find(chat_id)

# Generate response with MCP tools, resources, and prompts
result = ChatService.generate_response(
  chat, 
  "Can you help me find all Ruby files in my project?", 
  mcp_client
)

puts result[:message].content
puts "Success: #{result[:success]}"
```

### 3. Generate Titles with MCP

```ruby
# Generate a title using MCP context
title = ChatService.generate_title(chat, mcp_client)
```

## Available MCP Features

### Tools
MCP servers can provide tools that the LLM can use:

```ruby
# List available tools
tools = mcp_client.tools
tools.each do |tool|
  puts "#{tool.name}: #{tool.description}"
end

# The LLM will automatically use these tools when appropriate
```

### Resources
MCP servers can provide access to resources:

```ruby
# List available resources
resources = mcp_client.resources
resources.each do |resource|
  puts "#{resource.name}: #{resource.description}"
end

# Access resource content
file_resource = mcp_client.resource("project_readme")
content = file_resource.content
```

### Resource Templates
Parameterized resources that can be dynamically configured:

```ruby
# Get resource templates
templates = mcp_client.resource_templates
log_template = mcp_client.resource_template("application_logs")

# Use with parameters
content = log_template.to_content(arguments: {
  date: "2024-01-15",
  level: "error"
})
```

### Prompts
Predefined prompts with arguments:

```ruby
# List available prompts
prompts = mcp_client.prompts
prompts.each do |prompt|
  puts "#{prompt.name}: #{prompt.description}"
end

# Use a specific prompt
greeting_prompt = mcp_client.prompt("daily_greeting")
```

## Helper Service

The `McpService` provides helper methods for working with MCP clients:

```ruby
# List available tools in a formatted way
tools = McpService.list_available_tools(mcp_client)

# List available resources
resources = McpService.list_available_resources(mcp_client)

# List available prompts
prompts = McpService.list_available_prompts(mcp_client)
```

## Transport Types

MCP supports multiple transport types:

### STDIO
For local MCP servers that run as subprocesses:

```ruby
mcp_client = RubyLLM::MCP.client(
  name: "local-server",
  transport_type: :stdio,
  config: {
    command: "node",
    args: ["path/to/mcp-server.js"],
    env: { "NODE_ENV" => "production" }
  }
)
```

### Streamable HTTP
For HTTP-based MCP servers:

```ruby
mcp_client = RubyLLM::MCP.client(
  name: "http-server",
  transport_type: :streamable,
  config: {
    url: "http://localhost:8080/mcp",
    headers: { "Authorization" => "Bearer your-token" }
  }
)
```

### SSE (Server-Sent Events)
For SSE-based MCP servers:

```ruby
mcp_client = RubyLLM::MCP.client(
  name: "sse-server",
  transport_type: :sse,
  config: {
    url: "http://localhost:9292/mcp/sse"
  }
)
```

## Integration with Controllers

The `MessagesController` includes a `get_mcp_client` method that you can customize:

```ruby
# In app/controllers/messages_controller.rb
def get_mcp_client
  # Example: Get MCP client from chat settings
  return nil unless @chat.mcp_server_url.present?
  
  RubyLLM::MCP.client(
    name: "chat-#{@chat.id}",
    transport_type: :streamable,
    config: {
      url: @chat.mcp_server_url,
      headers: { "Authorization" => "Bearer #{@chat.mcp_auth_token}" }
    }
  )
end
```

## Popular MCP Servers

Here are some popular MCP servers you can integrate:

### File System Server
```bash
npm install @modelcontextprotocol/server-filesystem
```

### Web Search Server
```bash
npm install @modelcontextprotocol/server-web-search
```

### Database Server
```bash
npm install @modelcontextprotocol/server-sqlite
```

### GitHub Server
```bash
npm install @modelcontextprotocol/server-github
```

## Error Handling

MCP integration includes robust error handling:

- If an MCP client fails to connect, the chat will continue without MCP features
- If MCP tools fail, the LLM will respond with an error message
- All MCP operations are wrapped in try-catch blocks

## Testing

The MCP integration includes comprehensive tests:

```bash
# Run MCP service tests
bundle exec rspec spec/services/mcp_service_spec.rb

# Run ChatService tests with MCP
bundle exec rspec spec/services/chat_service_spec.rb
```

## Future Enhancements

Planned features for MCP integration:

- [ ] MCP client management per user/chat
- [ ] MCP server configuration UI
- [ ] MCP tool usage analytics
- [ ] MCP resource caching
- [ ] MCP prompt templates
- [ ] MCP server health monitoring

## Resources

- [RubyLLM::MCP Documentation](https://github.com/ruby-llm/ruby-llm-mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [MCP Server Registry](https://mcp.dev/servers/)
