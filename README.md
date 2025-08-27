# SkyTorch

A Rails 8 application for AI-powered chat conversations with MCP (Model Context Protocol) integration.

## Features

- **Chat Interface**: Modern, responsive chat UI with real-time messaging
- **LLM Integration**: Support for multiple LLM providers (OpenAI, Anthropic, Google)
- **MCP Tools**: Integration with Model Context Protocol for enhanced AI capabilities
- **User Management**: User authentication and chat isolation
- **Responsive Design**: Mobile-first design with collapsible sidebar

## Architecture

### Models
- `Chat`: Represents chat conversations
- `Message`: Individual messages within chats (user, assistant, system)

### Services
- `ChatService`: Handles chat interactions with LLM integration

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

## Usage

1. **Create a new chat** from the homepage
2. **Send messages** in the chat interface
3. **AI responses** will be generated using the configured LLM provider

## Development

### Environment Variables

You may need to set up environment variables for:
- LLM API keys (depending on your ruby_llm configuration)
- Database credentials

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
