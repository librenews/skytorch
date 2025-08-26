require 'ruby_llm'

class ChatService
  def initialize(chat, provider = nil)
    @chat = chat
    @provider = provider || LlmProvider.default_provider
    configure_llm
  end
  
  def send_message(content)
    # Add the user message to the LLM chat context
    @llm.add_message(role: 'user', content: content)
    
    # Check if the message contains MCP tool requests - more robust detection
    if should_add_mcp_context?(content)
      Rails.logger.info "Adding MCP context for message: #{content}"
      # Add MCP context to the prompt
      mcp_context = generate_mcp_context
      Rails.logger.info "MCP Context: #{mcp_context}"
      @llm.add_message(role: 'system', content: mcp_context)
    else
      Rails.logger.info "No MCP context needed for message: #{content}"
    end
    
    # Generate response using LLM
    response = @llm.complete
    Rails.logger.info "AI Response: #{response.content}"
    
    # Check if the AI response contains tool execution requests
    processed_response = process_tool_execution(response.content)
    
    # Extract rate limit information from response headers
    raw_response = response.instance_variable_get(:@raw)
    headers = raw_response.env.response_headers
    
    # Add assistant response to chat
    assistant_message = @chat.messages.create!(
      content: processed_response,
      role: 'assistant'
    )
    
    # Return both the message and rate limit info
    {
      message: assistant_message,
      rate_limits: {
        remaining_requests: headers['x-ratelimit-remaining-requests'],
        limit_requests: headers['x-ratelimit-limit-requests'],
        remaining_tokens: headers['x-ratelimit-remaining-tokens'],
        limit_tokens: headers['x-ratelimit-limit-tokens']
      }
    }
  end
  
  private
  
  def should_add_mcp_context?(content)
    # More robust detection of MCP-related requests
    content_lower = content.downcase
    
    result = content_lower.include?("tool") ||
    content_lower.include?("get_chat_info") ||
    content_lower.include?("create_test_message") ||
    content_lower.include?("chat info") ||
    content_lower.include?("test message") ||
    content_lower.include?("mcp") ||
    content_lower.include?("capability") ||
    content_lower.include?("access") ||
    content_lower.include?("external data") ||
    content_lower.include?("use the") ||
    content_lower.include?("can you use") ||
    content_lower.include?("tell me about") ||
    content_lower.include?("information about") ||
    content_lower.include?("create a message") ||
    content_lower.include?("add a message")
    
    Rails.logger.info "MCP context check for '#{content}': #{result}"
    Rails.logger.info "Content contains 'tool': #{content_lower.include?('tool')}"
    Rails.logger.info "Content contains 'get_chat_info': #{content_lower.include?('get_chat_info')}"
    Rails.logger.info "Content contains 'use the': #{content_lower.include?('use the')}"
    Rails.logger.info "Content contains 'can you use': #{content_lower.include?('can you use')}"
    
    result
  end
  
  def process_tool_execution(response_content)
    # Look for tool execution patterns in the AI response
    if response_content.include?("get_chat_info")
      Rails.logger.info "Executing get_chat_info tool"
      # Execute get_chat_info tool
      result = SkytorchMcpServer.call_tool("get_chat_info", { "chat_id" => @chat.id })
      return response_content + "\n\n**Tool Result:**\n```json\n#{JSON.pretty_generate(result)}\n```"
    elsif response_content.include?("create_test_message") || response_content.include?("create a test message") || response_content.include?("add a message")
      Rails.logger.info "Executing create_test_message tool"
      # Try to extract custom content from the response
      content = extract_test_message_content(response_content)
      
      # Execute create_test_message tool
      result = SkytorchMcpServer.call_tool("create_test_message", { 
        "chat_id" => @chat.id, 
        "content" => content
      })
      return response_content + "\n\n**Tool Result:**\n```json\n#{JSON.pretty_generate(result)}\n```"
    end
    
    response_content
  end
  
  def extract_test_message_content(response_content)
    # Try to extract custom content from the AI response
    # Look for patterns like "with content: ..." or "message: ..."
    if response_content =~ /content:\s*["']([^"']+)["']/i
      return $1
    elsif response_content =~ /message:\s*["']([^"']+)["']/i
      return $1
    elsif response_content =~ /test message:\s*["']([^"']+)["']/i
      return $1
    end
    
    # Default content
    "This is a test message created via MCP tool"
  end
  
  def generate_mcp_context
    tools = SkytorchMcpServer.available_tools
    tool_descriptions = tools.map do |tool|
      "- #{tool[:name]}: #{tool[:description]}"
    end.join("\n")
    
    "You have access to the following MCP tools:\n#{tool_descriptions}\n\n" +
    "IMPORTANT: You DO have access to these tools. When users ask about them, you should mention that you can use them.\n" +
    "If the user asks about chat information, mention that you can use the get_chat_info tool.\n" +
    "If the user asks about creating test messages, mention that you can use the create_test_message tool.\n" +
    "When you mention using a tool, I will automatically execute it and show you the results.\n" +
    "For create_test_message, you can specify custom content like: 'with content: \"your custom message\"'\n" +
    "Do NOT say you don't have access to tools - you DO have access to these MCP tools.\n" +
    "IMPORTANT: When users ask you to do something that requires a tool, automatically mention that you'll use the appropriate tool and I will execute it for you."
  end
  
  def configure_llm
    if @provider
      # Configure ruby_llm with the provider settings
      RubyLLM.configure do |config|
        case @provider.provider_type
        when 'openai'
          config.openai_api_key = @provider.api_key
          config.default_model = @provider.default_model if @provider.default_model.present?
        when 'anthropic'
          config.anthropic_api_key = @provider.api_key
          config.default_model = @provider.default_model if @provider.default_model.present?
        when 'google'
          config.gemini_api_key = @provider.api_key
          config.default_model = @provider.default_model if @provider.default_model.present?
        end
      end
      
      @llm = RubyLLM::Chat.new
    else
      # Fallback to mock provider if no provider is configured
      @llm = RubyLLM::Chat.new
    end
  end
end
