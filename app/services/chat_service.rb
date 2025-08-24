class ChatService
  def initialize(chat, provider = nil)
    @chat = chat
    @provider = provider || LlmProvider.default_provider
    @llm = create_llm_client
  end
  
  def send_message(content)
    # Add user message to chat
    user_message = @chat.messages.create!(
      content: content,
      role: 'user'
    )
    
    # Get chat history for context
    messages = @chat.messages.order(:created_at).map do |msg|
      { role: msg.role, content: msg.content }
    end
    
    # Get available tools from our MCP server
    tools = SkytorchMcpServer.available_tools
    
    # Generate response using LLM with MCP tools
    response = @llm.chat(
      messages: messages,
      tools: tools,
      tool_choice: "auto"
    )
    
    # Add assistant response to chat
    assistant_message = @chat.messages.create!(
      content: response.content,
      role: 'assistant'
    )
    
    # Handle tool calls if any
    if response.tool_calls.any?
      handle_tool_calls(response.tool_calls, assistant_message)
    end
    
    assistant_message
  end
  
  private
  
  def create_llm_client
    if @provider
      RubyLLM::Client.new(@provider.provider_config)
    else
      # Fallback to mock provider if no provider is configured
      RubyLLM::Client.new(provider: :mock)
    end
  end
  
  def handle_tool_calls(tool_calls, message)
    tool_calls.each do |tool_call|
      # Execute tool call through our MCP server
      result = SkytorchMcpServer.call_tool(tool_call.name, tool_call.arguments)
      
      # Add tool result as a system message
      @chat.messages.create!(
        content: "Tool result: #{result}",
        role: 'system'
      )
    end
  end
end
