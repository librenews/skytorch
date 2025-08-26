#!/bin/bash

echo "Testing MCP endpoint..."

# Test tools/list
echo "1. Testing tools/list..."
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'

echo -e "\n\n2. Testing tools/call..."
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "get_chat_info",
      "arguments": {"chat_id": 1}
    }
  }'

echo -e "\n\nMCP test complete!"
