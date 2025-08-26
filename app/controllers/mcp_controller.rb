class McpController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def handle
    # Parse the request
    request_data = JSON.parse(request.body.read)
    
    # Handle the request using the MCP server
    begin
      # Try to load the service class if it's not already loaded
      unless defined?(SkytorchMcpServer)
        Rails.logger.info "Loading SkytorchMcpServer service..."
        load Rails.root.join('app', 'services', 'skytorch_mcp_server.rb')
      end
      
      Rails.logger.info "Checking if SkytorchMcpServer exists: #{defined?(SkytorchMcpServer)}"
      
      response = SkytorchMcpServer.handle_request(request_data)
      render json: response
    rescue => e
      Rails.logger.error "MCP Error: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      render json: {
        jsonrpc: "2.0",
        id: request_data["id"],
        error: {
          code: -32603,
          message: "Internal error: #{e.message}"
        }
      }, status: 500
    end
  end
end
