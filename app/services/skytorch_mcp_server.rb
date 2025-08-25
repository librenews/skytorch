class SkyTorchMcpServer
  def self.available_tools
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
      
    when "create_test_message"
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
      
    else
      { error: "Unknown tool: #{tool_name}" }
    end
  end
end
