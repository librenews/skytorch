# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a sample chat for testing
if Chat.count.zero?
  chat = Chat.create!(title: "Welcome to SkyTorch")
  
  # Add some initial messages
  chat.messages.create!([
    { content: "Hello! I'm your AI assistant. I can help you with various tasks using MCP tools.", role: "assistant" },
    { content: "What can you help me with?", role: "user" },
    { content: "I can help you with:\n\n• Getting information about chats\n• Creating test messages\n• And much more through MCP tools!\n\nJust ask me what you'd like to do.", role: "assistant" }
  ])
end

# Create a sample MCP server record
if McpServer.count.zero?
  McpServer.create!(
    name: "SkyTorch MCP Server",
    url: "http://localhost:3000/mcp",
    description: "The main MCP server for this application"
  )
end

# Create OpenAI provider (API key should be set via environment variables)
if LlmProvider.count.zero?
  # Only create provider if API key is available
  if ENV['OPENAI_API_KEY'].present?
    LlmProviderService.create_openai_provider(
      ENV['OPENAI_API_KEY'],
      "gpt-4o-mini"
    )
  else
    puts "Warning: OPENAI_API_KEY not set. Skipping LLM provider creation."
  end
end
