#!/usr/bin/env ruby

# Test script for Chat + MCP integration
require_relative 'config/environment'

def test_chat_mcp_integration
  puts "Testing Chat + MCP Integration..."
  
  # Create a test user and chat
  user = User.first || User.create!(
    bluesky_did: 'did:plc:test',
    bluesky_handle: 'test.user',
    display_name: 'Test User'
  )
  
  chat = user.chats.create!(title: "MCP Chat Test")
  
  # Test 1: Simple message without MCP
  puts "\n1. Testing simple message..."
  begin
    chat_service = ChatService.new(chat)
    result = chat_service.send_message("Hello, how are you?")
    puts "✓ Simple message sent: #{result[:message].content[0..50]}..."
  rescue => e
    puts "✗ Simple message failed: #{e.message}"
  end
  
  # Test 2: Message requesting MCP tool
  puts "\n2. Testing message with MCP tool request..."
  begin
    chat_service = ChatService.new(chat)
    result = chat_service.send_message("Can you use the get_chat_info tool to tell me about this chat?")
    puts "✓ MCP tool request sent: #{result[:message].content[0..50]}..."
  rescue => e
    puts "✗ MCP tool request failed: #{e.message}"
  end
  
  # Test 3: Direct MCP tool call from chat context
  puts "\n3. Testing direct MCP tool call..."
  begin
    mcp_result = SkytorchMcpServer.call_tool("get_chat_info", { "chat_id" => chat.id })
    puts "✓ Direct MCP call successful: #{mcp_result}"
  rescue => e
    puts "✗ Direct MCP call failed: #{e.message}"
  end
  
  puts "\nChat + MCP Integration Test Complete!"
end

if __FILE__ == $0
  test_chat_mcp_integration
end
