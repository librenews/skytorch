class ConversationManager
  def initialize(chat)
    @chat = chat
    @state_manager = get_or_create_conversation_state
    @mcp_clients = McpClientRegistry.get_clients_for_chat(chat)
    @tool_orchestrator = ToolOrchestrator.new(@mcp_clients)
  end

  def process_message(user_message)
    current_status = @state_manager.status
    
    case current_status
    when 'normal'
      handle_normal_message(user_message)
    when 'collecting_params'
      handle_parameter_collection(user_message)
    when 'executing_tools'
      handle_tool_execution(user_message)
    else
      # Fallback to normal message handling
      handle_normal_message(user_message)
    end
  end

  private

  def handle_normal_message(user_message)
    # 1. Detect needed tools
    required_tools = @tool_orchestrator.detect_required_tools(user_message)
    
    if required_tools.any?
      # 2. Check for missing parameters
      missing_params = @tool_orchestrator.check_missing_parameters(required_tools)
      
      if missing_params.any?
        # 3. Generate clarification question
        clarification = @tool_orchestrator.generate_clarification_question(missing_params)
        
        # 4. Update state to collecting_params
        @state_manager.update!(
          status: 'collecting_params',
          pending_tools: required_tools.map { |tool| { name: tool.name, parameters: {} } },
          missing_params: missing_params,
          original_message: user_message
        )
        
        return { type: :clarification, content: clarification }
      else
        # 5. Execute tools directly
        return execute_tool_chain(required_tools, user_message)
      end
    else
      # 6. Normal LLM response
      return generate_normal_response(user_message)
    end
  end

  def handle_parameter_collection(user_message)
    # Classify user intent
    intent = @tool_orchestrator.classify_user_intent(user_message)
    
    case intent
    when :provide_param
      # Fill missing parameter
      @state_manager.fill_parameter(user_message)
      
      # Check if all params are filled
      if @state_manager.all_parameters_filled?
        return execute_tool_chain(@state_manager.pending_tools, @state_manager.original_message)
      else
        # Generate next clarification question
        clarification = @tool_orchestrator.generate_clarification_question(@state_manager.missing_params)
        return { type: :clarification, content: clarification }
      end
      
    when :cancel
      @state_manager.clear_state
      return { type: :cancelled, content: "Okay, cancelled." }
      
    when :new_topic
      @state_manager.clear_state
      return generate_normal_response(user_message)
    else
      # Default to parameter collection
      @state_manager.fill_parameter(user_message)
      
      if @state_manager.all_parameters_filled?
        return execute_tool_chain(@state_manager.pending_tools, @state_manager.original_message)
      else
        clarification = @tool_orchestrator.generate_clarification_question(@state_manager.missing_params)
        return { type: :clarification, content: clarification }
      end
    end
  end

  def handle_tool_execution(user_message)
    # This state is for future use if we need to handle multi-step tool execution
    # For now, just continue with normal processing
    handle_normal_message(user_message)
  end

  def execute_tool_chain(required_tools, original_message)
    # Update state to executing_tools
    @state_manager.update!(status: 'executing_tools')
    
    # Convert tools to tool calls format
    tool_calls = required_tools.map do |tool|
      { name: tool.name, parameters: @state_manager.collected_params }
    end
    
    # Execute tool chain
    tool_results = @tool_orchestrator.execute_tool_chain(tool_calls, @state_manager.collected_params)
    
    # Handle any failed tools
    failed_tools = tool_results.select { |r| r[:error] }
    failed_tools.each do |failed_tool|
      @state_manager.remove_failed_tool(failed_tool[:tool])
    end
    
    # Generate final response with partial results
    final_response = @tool_orchestrator.generate_response_with_partial_results(original_message, tool_results)
    
    # Clear state
    @state_manager.clear_state
    
    # Return error message if any tools failed
    if failed_tools.any?
      error_message = "⚠️ Some services encountered issues. I'll continue with the available information."
      return { type: :error, content: error_message, final_response: final_response }
    else
      return { type: :final_response, content: final_response }
    end
  end

  def generate_normal_response(user_message)
    # Use the existing ChatService logic for normal responses
    result = ChatService.generate_simple_response(@chat, user_message)
    { type: :final_response, content: result[:message].content }
  end

  def get_or_create_conversation_state
    @chat.conversation_state || @chat.create_conversation_state(status: 'normal')
  end
end
