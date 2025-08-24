class DashboardController < ApplicationController
  def index
    @chats = Chat.order(created_at: :desc).limit(10)
    @llm_providers = LlmProvider.active
    @current_provider = LlmProvider.default_provider
    @connection_status = check_llm_connection_status
  end

  def connection_status
    @current_provider = LlmProvider.default_provider
    status = check_llm_connection_status
    
    render json: {
      status: status[:status],
      message: status[:message],
      provider_name: @current_provider&.name,
      usage: status[:usage]
    }
  end

  private

  def check_llm_connection_status
    return { status: 'disconnected', message: 'No active provider' } unless @current_provider

    begin
      # Test the connection by making a simple API call
      chat_service = ChatService.new(Chat.new, @current_provider)
      
      # Configure the LLM
      chat_service.send(:configure_llm)
      
      # Make a simple test call to validate the API key
      llm = chat_service.instance_variable_get(:@llm)
      llm.add_message(role: 'user', content: 'test')
      
      # Try to get a response (this will actually test the API)
      response = llm.complete
      
      # Extract rate limit information from response headers
      raw_response = response.instance_variable_get(:@raw)
      headers = raw_response.env.response_headers
      
      # Calculate usage percentages
      remaining_requests = headers['x-ratelimit-remaining-requests'].to_i
      limit_requests = headers['x-ratelimit-limit-requests'].to_i
      remaining_tokens = headers['x-ratelimit-remaining-tokens'].to_i
      limit_tokens = headers['x-ratelimit-limit-tokens'].to_i
      
      requests_usage_pct = ((limit_requests - remaining_requests).to_f / limit_requests * 100).round(1)
      tokens_usage_pct = ((limit_tokens - remaining_tokens).to_f / limit_tokens * 100).round(1)
      
      # Determine status based on usage
      if requests_usage_pct > 90 || tokens_usage_pct > 90
        status = 'warning'
        message = "High usage: #{requests_usage_pct}% requests, #{tokens_usage_pct}% tokens used"
      elsif requests_usage_pct > 75 || tokens_usage_pct > 75
        status = 'warning'
        message = "Moderate usage: #{requests_usage_pct}% requests, #{tokens_usage_pct}% tokens used"
      else
        status = 'connected'
        message = "Connected to #{@current_provider.name} (#{requests_usage_pct}% requests, #{tokens_usage_pct}% tokens used)"
      end
      
      {
        status: status,
        message: message,
        usage: {
          requests: { used: limit_requests - remaining_requests, limit: limit_requests, remaining: remaining_requests, percentage: requests_usage_pct },
          tokens: { used: limit_tokens - remaining_tokens, limit: limit_tokens, remaining: remaining_tokens, percentage: tokens_usage_pct },
          reset_requests: headers['x-ratelimit-reset-requests'],
          reset_tokens: headers['x-ratelimit-reset-tokens']
        }
      }
    rescue => e
      Rails.logger.error "LLM connection test failed: #{e.message}"
      { status: 'disconnected', message: 'Connection failed: ' + e.message }
    end
  end
end
