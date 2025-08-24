class McpController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def handle
    # Parse the request
    request_data = JSON.parse(request.body.read)
    
    # Handle different types of MCP requests
    case request_data["method"]
    when "tools/list"
      render json: {
        jsonrpc: "2.0",
        id: request_data["id"],
        result: {
          tools: SkytorchMcpServer.available_tools
        }
      }
      
    when "tools/call"
      tool_name = request_data["params"]["name"]
      arguments = request_data["params"]["arguments"]
      
      result = SkytorchMcpServer.call_tool(tool_name, arguments)
      
      render json: {
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
      render json: {
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
