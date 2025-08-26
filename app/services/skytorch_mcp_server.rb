class SkytorchMcpServer
  def self.available_tools
    # Return tools in the format expected by the controller
    [
      {
        name: "get_chat_info",
        description: "Get information about a chat",
        input_schema: {
          type: "object",
          properties: {
            chat_id: {
              type: "integer",
              description: "The ID of the chat to get info for"
            }
          },
          required: ["chat_id"]
        }
      },
      {
        name: "create_test_message",
        description: "Create a test message in a chat",
        input_schema: {
          type: "object",
          properties: {
            chat_id: {
              type: "integer",
              description: "The ID of the chat to add the message to"
            },
            content: {
              type: "string",
              description: "The content of the test message"
            }
          },
          required: ["chat_id", "content"]
        }
      }
    ]
  end
  
  def self.call_tool(tool_name, params)
    case tool_name
    when "get_chat_info"
      get_chat_info(params)
    when "create_test_message"
      create_test_message(params)
    else
      { error: "Unknown tool: #{tool_name}" }
    end
  end
  
  def self.get_chat_info(params)
    chat_id = params["chat_id"]
    chat = Chat.find_by(id: chat_id)
    
    if chat
      {
        id: chat.id,
        title: chat.title,
        message_count: chat.messages.count,
        created_at: chat.created_at,
        updated_at: chat.updated_at
      }
    else
      { error: "Chat not found" }
    end
  end
  
  def self.create_test_message(params)
    chat_id = params["chat_id"]
    content = params["content"]
    
    chat = Chat.find_by(id: chat_id)
    if chat
      message = chat.messages.create!(
        content: content,
        role: "system"
      )
      {
        id: message.id,
        content: message.content,
        role: message.role,
        created_at: message.created_at
      }
    else
      { error: "Chat not found" }
    end
  end
  
  # Method to handle MCP requests (for future use with proper MCP gem)
  def self.handle_request(request_data)
    case request_data["method"]
    when "tools/list"
      {
        jsonrpc: "2.0",
        id: request_data["id"],
        result: {
          tools: available_tools
        }
      }
    when "tools/call"
      tool_name = request_data["params"]["name"]
      arguments = request_data["params"]["arguments"]
      result = call_tool(tool_name, arguments)
      
      {
        jsonrpc: "2.0",
        id: request_data["id"],
        result: {
          content: [
            {
              type: "text",
              text: result.to_json
            }
          ]
        }
      }
    else
      {
        jsonrpc: "2.0",
        id: request_data["id"],
        error: {
          code: -32601,
          message: "Method not found"
        }
      }
    end
  end
end
