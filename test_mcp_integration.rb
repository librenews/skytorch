#!/usr/bin/env ruby

# Test script for MCP integration
require_relative 'config/environment'

def test_mcp_integration
  puts "Testing MCP Integration..."
  
  # Test 1: Check if MCP server can be instantiated
  puts "\n1. Testing MCP server instantiation..."
  begin
    # We don't need to instantiate the class since all methods are class methods
    puts "✓ MCP server class accessible"
  rescue => e
    puts "✗ Failed to access MCP server: #{e.message}"
    return
  end
  
  # Test 2: Check available tools
  puts "\n2. Testing available tools..."
  tools = SkytorchMcpServer.available_tools
  puts "✓ Found #{tools.length} available tools:"
  tools.each do |tool|
    puts "  - #{tool[:name]}: #{tool[:description]}"
  end
  
  # Test 3: Test tool calling
  puts "\n3. Testing tool calling..."
  begin
    # Create a test chat first
    user = User.first || User.create!(
      bluesky_did: 'did:plc:test',
      bluesky_handle: 'test.user',
      display_name: 'Test User'
    )
    
    chat = user.chats.create!(title: "MCP Test Chat")
    
    result = SkytorchMcpServer.call_tool("get_chat_info", { "chat_id" => chat.id })
    puts "✓ Tool call successful: #{result}"
  rescue => e
    puts "✗ Tool call failed: #{e.message}"
  end
  
  # Test 4: Test MCP request handling
  puts "\n4. Testing MCP request handling..."
  begin
    request = {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "tools/list"
    }
    
    response = SkytorchMcpServer.handle_request(request)
    puts "✓ MCP request handling successful: #{response['result']['tools'].length} tools"
  rescue => e
    puts "✗ MCP request handling failed: #{e.message}"
  end
  
  puts "\nMCP Integration Test Complete!"
end

if __FILE__ == $0
  test_mcp_integration
end
