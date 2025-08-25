# SkyTorch

A Rails 8 application that integrates ruby_llm for chat functionality and ruby_llm-mcp for Model Context Protocol (MCP) integration. The application serves as both a chat client and an MCP server.

## Features

- **Chat Interface**: Modern chat UI built with Rails 8, Tailwind CSS, and Stimulus
- **LLM Integration**: Powered by ruby_llm for AI chat capabilities
- **MCP Client**: Uses ruby_llm-mcp to connect to MCP servers dynamically
- **MCP Server**: Built-in MCP server using the mcp gem
- **Dynamic Server Management**: Stub class for providing MCP servers dynamically
- **PostgreSQL**: Database backend with proper associations

## Architecture

### Models
- `Chat`: Represents chat conversations
- `Message`: Individual messages within chats (user, assistant, system)
- `McpServer`: Stores MCP server configurations

### Services
- `ChatService`: Handles chat interactions with LLM and MCP integration
- `McpServerProvider`: Stub class for dynamically providing MCP servers
- `SkyTorchMcpServer`: MCP server implementation with test tools

### MCP Tools
The built-in MCP server provides:
- `get_chat_info`: Retrieve information about a specific chat
- `create_test_message`: Create a test message in a chat

## Setup

1. **Install dependencies**:
   ```bash
   bundle install
   yarn install
   ```

2. **Set up the database**:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

3. **Start the development server**:
   ```bash
   bin/dev
   ```

4. **Access the application**:
   - Main app: http://localhost:3000
   - MCP endpoint: http://localhost:3000/mcp

## Usage

1. **Create a new chat** from the homepage
2. **Send messages** in the chat interface
3. **AI responses** will be generated using ruby_llm
4. **MCP tools** can be used by the AI when appropriate

## Development

### Adding New MCP Tools

To add new tools to the MCP server, edit `app/services/skytorch_mcp_server.rb`:

```ruby
register_tool(
  name: "your_tool_name",
  description: "Description of what the tool does",
  input_schema: {
    type: "object",
    properties: {
      # Define your parameters here
    },
    required: ["required_param"]
  }
) do |params|
  # Your tool implementation
  { result: "success" }
end
```

### Dynamic MCP Server Management

The `McpServerProvider` class is currently a stub that returns a hardcoded server. In production, this would be replaced with logic that:

1. Discovers available MCP servers
2. Manages server configurations
3. Handles authentication and connection management

### Environment Variables

You may need to set up environment variables for:
- LLM API keys (depending on your ruby_llm configuration)
- Database credentials
- MCP server configurations

## Testing

Run the test suite:
```bash
rails test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
