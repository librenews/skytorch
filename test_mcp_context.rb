#!/usr/bin/env ruby

# Test script to verify MCP context is being added
require_relative 'config/environment'

def test_mcp_context
  puts "Testing MCP Context Injection..."
  
  # Create a test user and chat
  user = User.first || User.create!(
    bluesky_did: 'did:plc:test',
    bluesky_handle: 'test.user',
    display_name: 'Test User'
  )
  
  chat = user.chats.create!(title: "MCP Context Test")
  
  # Test 1: Message that should trigger MCP context
  puts "\n1. Testing message with 'tool' keyword:"
  puts "User: Can you use the get_chat_info tool to tell me about this chat?"
  
  begin
    chat_service = ChatService.new(chat)
    
    # Check if MCP context should be added
    should_add = chat_service.send(:should_add_mcp_context?, "Can you use the get_chat_info tool to tell me about this chat?")
    puts "Should add MCP context: #{should_add}"
    
    # Get the MCP context that would be added
    mcp_context = chat_service.send(:generate_mcp_context)
    puts "MCP Context:"
    puts mcp_context
    puts "---"
    
    # Test the actual message
    result = chat_service.send_message("Can you use the get_chat_info tool to tell me about this chat?")
    puts "AI Response: #{result[:message].content}"
    
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(5)
  end
  
  # Test 2: Message that shouldn't trigger MCP context
  puts "\n2. Testing regular message:"
  puts "User: Hello, how are you?"
  
  begin
    should_add = chat_service.send(:should_add_mcp_context?, "Hello, how are you?")
    puts "Should add MCP context: #{should_add}"
    
    result = chat_service.send_message("Hello, how are you?")
    puts "AI Response: #{result[:message].content[0..100]}..."
    
  rescue => e
    puts "Error: #{e.message}"
  end
  
  puts "\nTest complete!"
end

if __FILE__ == $0
  test_mcp_context
end
