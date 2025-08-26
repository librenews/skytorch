#!/usr/bin/env ruby

# Test the original message that should trigger MCP
require_relative 'config/environment'

def test_original_message
  puts "Testing Original Message with MCP..."
  
  # Create a test user and chat
  user = User.first || User.create!(
    bluesky_did: 'did:plc:test',
    bluesky_handle: 'test.user',
    display_name: 'Test User'
  )
  
  chat = user.chats.create!(title: "Original Message Test")
  
  # Test the original message that should trigger MCP
  original_message = "Can you use the get_chat_info tool to tell me about this chat?"
  puts "\nTesting message: '#{original_message}'"
  
  begin
    chat_service = ChatService.new(chat)
    
    # Check if MCP context should be added
    should_add = chat_service.send(:should_add_mcp_context?, original_message)
    puts "Should add MCP context: #{should_add}"
    
    if should_add
      # Get the MCP context that would be added
      mcp_context = chat_service.send(:generate_mcp_context)
      puts "MCP Context:"
      puts mcp_context
      puts "---"
    end
    
    # Test the actual message
    result = chat_service.send_message(original_message)
    puts "AI Response: #{result[:message].content}"
    
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(5)
  end
  
  puts "\nTest complete!"
end

if __FILE__ == $0
  test_original_message
end
