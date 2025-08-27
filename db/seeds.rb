# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a sample user for testing
if User.count.zero?
  user = User.create!(
    bluesky_handle: "test.user",
    bluesky_did: "did:plc:testuser123",
    display_name: "Test User"
  )
  
  # Create a sample chat for testing
  chat = user.chats.create!(title: "Welcome to SkyTorch")
  
  # Add some initial messages
  chat.messages.create!([
    { content: "Hello! I'm your AI assistant. I can help you with various tasks.", role: "assistant" },
    { content: "What can you help me with?", role: "user" },
    { content: "I can help you with:\n\n• Getting information about chats\n• Creating test messages\n• And much more!\n\nJust ask me what you'd like to do.", role: "assistant" }
  ])
end

# Create OpenAI provider (API key should be set via environment variables)
if Provider.count.zero?
  # Only create provider if API key is available
  if ENV['OPENAI_API_KEY'].present?
    ProviderService.create_openai_provider(
      ENV['OPENAI_API_KEY'],
      "gpt-4o-mini"
    )
  else
    puts "Warning: OPENAI_API_KEY not set. Skipping LLM provider creation."
  end
end
