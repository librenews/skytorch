#!/usr/bin/env ruby

# Simple test for MCP with the original message
require_relative 'config/environment'

def test_simple_mcp
  puts "=== Simple MCP Test ==="
  
  # Test the detection logic directly
  test_message = "Can you use the get_chat_info tool to tell me about this chat?"
  
  puts "Testing message: '#{test_message}'"
  
  # Create a temporary chat service to test the detection
  user = User.first || User.create!(
    bluesky_did: 'did:plc:test',
    bluesky_handle: 'test.user',
    display_name: 'Test User'
  )
  
  chat = user.chats.create!(title: "Simple Test")
  chat_service = ChatService.new(chat)
  
  # Test the detection method
  should_add = chat_service.send(:should_add_mcp_context?, test_message)
  puts "Should add MCP context: #{should_add}"
  
  if should_add
    puts "✓ MCP context will be added!"
    
    # Test the actual message
    puts "\nSending message to chat..."
    result = chat_service.send_message(test_message)
    puts "AI Response: #{result[:message].content}"
  else
    puts "✗ MCP context will NOT be added"
  end
  
  puts "\n=== Test Complete ==="
end

if __FILE__ == $0
  test_simple_mcp
end
