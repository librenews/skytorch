#!/usr/bin/env ruby

# Demo script showing how MCP works in chat
require_relative 'config/environment'

def demo_chat_mcp
  puts "=== MCP Chat Integration Demo ===\n"
  
  # Create a test user and chat
  user = User.first || User.create!(
    bluesky_did: 'did:plc:demo',
    bluesky_handle: 'demo.user',
    display_name: 'Demo User'
  )
  
  chat = user.chats.create!(title: "MCP Demo Chat")
  
  # Demo 1: Basic chat without MCP
  puts "\n1. Basic chat message:"
  puts "User: Hello, how are you?"
  
  begin
    chat_service = ChatService.new(chat)
    result = chat_service.send_message("Hello, how are you?")
    puts "AI: #{result[:message].content[0..100]}..."
  rescue => e
    puts "Error: #{e.message}"
  end
  
  # Demo 2: Chat info request
  puts "\n2. Chat info request:"
  puts "User: Can you tell me about this chat?"
  
  begin
    result = chat_service.send_message("Can you tell me about this chat?")
    puts "AI: #{result[:message].content}"
  rescue => e
    puts "Error: #{e.message}"
  end
  
  # Demo 3: Test message creation
  puts "\n3. Test message creation:"
  puts "User: Can you create a test message with content: 'Hello from MCP!'"
  
  begin
    result = chat_service.send_message("Can you create a test message with content: 'Hello from MCP!'")
    puts "AI: #{result[:message].content}"
  rescue => e
    puts "Error: #{e.message}"
  end
  
  # Demo 4: Show available tools
  puts "\n4. Tool discovery:"
  puts "User: What tools do you have available?"
  
  begin
    result = chat_service.send_message("What tools do you have available?")
    puts "AI: #{result[:message].content}"
  rescue => e
    puts "Error: #{e.message}"
  end
  
  puts "\n=== Demo Complete ==="
  puts "Check the chat in the database to see the created messages!"
end

if __FILE__ == $0
  demo_chat_mcp
end
