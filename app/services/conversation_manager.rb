class ConversationManager
  def initialize(chat, mcp_clients)
    @chat = chat
    @mcp_clients = mcp_clients
    @tool_orchestrator = ToolOrchestrator.new(mcp_clients)
    @state_manager = ConversationState.find_or_create_by(chat: chat)
  end

  def process_message(user_message)
    # Check if we're waiting for parameters
    if @state_manager.pending_tool_names.any?
      # Check if user is providing a parameter
      if looks_like_parameter(user_message)
        @state_manager.fill_parameter(user_message)
        
        # Get the actual tool objects for the pending tools
        pending_tools = get_tools_by_names(@state_manager.pending_tool_names)
        
        # Check if we have all parameters now
        missing_params = @tool_orchestrator.check_missing_parameters(
          pending_tools, 
          @state_manager.collected_params
        )
        
        if missing_params.empty?
          # Execute the tools
          return execute_pending_tools(user_message)
        else
          # Still need more parameters
          question = @tool_orchestrator.generate_clarification_question(missing_params)
          return { type: :clarification, content: question }
        end
      else
        # User changed topic, clear pending tools
        @state_manager.clear_pending_tools
      end
    end

    # Normal message processing
    handle_normal_message(user_message)
  end

  private

  def handle_normal_message(user_message)
    # Detect if tools are needed
    required_tools = @tool_orchestrator.detect_required_tools(user_message)
    
    if required_tools.empty?
      # No tools needed, let the normal chat flow handle it
      return { type: :normal, content: nil }
    end

    # Check for missing parameters
    missing_params = @tool_orchestrator.check_missing_parameters(required_tools, {})
    
    if missing_params.empty?
      # Execute tools immediately
      return execute_tools(required_tools, user_message)
    else
      # Need to collect parameters
      @state_manager.set_pending_tools(required_tools)
      @state_manager.update_missing_params(missing_params)
      
      question = @tool_orchestrator.generate_clarification_question(missing_params)
      return { type: :clarification, content: question }
    end
  end

  def execute_tools(tools, original_message)
    # Convert tools to tool calls format
    tool_calls = tools.map do |tool|
      { name: tool.name, parameters: {} }
    end

    # Execute the tools
    results = @tool_orchestrator.execute_tool_chain(tool_calls, {})
    
    # Generate response
    response_content = @tool_orchestrator.generate_response_with_results(results, original_message)
    
    # Clear any pending state
    @state_manager.clear_pending_tools
    
    { type: :tool_response, content: response_content }
  end

  def execute_pending_tools(original_message)
    # Get the actual tool objects for the pending tools
    # If pending_tool_names is empty but we have missing_params, reconstruct from missing_params
    tool_names = @state_manager.pending_tool_names.any? ? 
      @state_manager.pending_tool_names : 
      @state_manager.missing_params.map { |param| param['tool'] }.uniq
    
    pending_tools = get_tools_by_names(tool_names)
    
    # Convert pending tools to tool calls
    tool_calls = pending_tools.map do |tool|
      { name: tool.name, parameters: {} }
    end

    # Execute with collected parameters
    results = @tool_orchestrator.execute_tool_chain(tool_calls, @state_manager.collected_params)
    
    # Generate response
    response_content = @tool_orchestrator.generate_response_with_results(results, original_message)
    
    # Clear pending state
    @state_manager.clear_pending_tools
    
    { type: :tool_response, content: response_content }
  end

  def get_tools_by_names(tool_names)
    all_tools = @tool_orchestrator.send(:collect_all_tools)
    all_tools.select { |tool| tool_names.include?(tool.name) }
  end

  def looks_like_parameter(message)
    # Simple heuristic: if it looks like a path or single value, it's probably a parameter
    message.strip.match?(/^[\/\w\-\.]+$/) && message.length < 100
  end
end
