class ToolOrchestrator
  def initialize(mcp_clients)
    @mcp_clients = mcp_clients.compact
    @available_tools = collect_all_tools
  end

  def detect_required_tools(user_message)
    return [] if @available_tools.empty?
    
    # Use LLM to determine which tools are needed
    llm_chat = RubyLLM.chat
    
    # Create a simple tool list for the LLM to analyze
    tool_list = @available_tools.map do |tool|
      "#{tool.name}: #{tool.description}"
    end.join("\n")
    
    response = llm_chat.ask(<<~PROMPT)
      Analyze this user message and determine which tools are needed:
      "#{user_message}"
      
      Available tools:
      #{tool_list}
      
      Return only the tool names that are needed, separated by commas. If no tools are needed, return 'none'.
    PROMPT
    
    tool_names = response.content.downcase.split(',').map(&:strip)
    return [] if tool_names.include?('none')
    
    @available_tools.select { |tool| tool_names.include?(tool.name.downcase) }
  end

  def check_missing_parameters(required_tools)
    missing_params = []
    
    required_tools.each do |tool|
      # Get the input schema to check required fields
      input_schema = tool.instance_variable_get(:@input_schema)
      required_fields = input_schema&.dig('required') || []
      
      # Get tool parameters from the ruby_llm-mcp Parameter objects
      tool.parameters&.each do |param_name, param|
        # Check if this parameter is required according to the schema
        if required_fields.include?(param_name) && param.default.nil?
          missing_params << {
            tool: tool.name,
            parameter: param_name,
            description: param.description || param_name
          }
        end
      end
    end
    
    missing_params
  end

  def execute_tool_chain(tool_calls, collected_params)
    results = []
    
    tool_calls.each_with_index do |tool_call, index|
      begin
        # Execute tool with collected parameters
        result = execute_single_tool(tool_call, collected_params)
        results << result
        
        # If this isn't the last tool, chain the output to the next tool
        if index < tool_calls.length - 1
          next_tool = tool_calls[index + 1]
          chain_output_to_next_tool(result, next_tool, collected_params)
        end
      rescue => e
        Rails.logger.error "Tool execution failed for #{tool_call[:name]}: #{e.message}"
        results << { tool: tool_call[:name], error: e.message }
      end
    end
    
    results
  end

  def generate_clarification_question(missing_params)
    return nil if missing_params.empty?
    
    llm_chat = RubyLLM.chat
    
    param_descriptions = missing_params.map do |param|
      "#{param[:parameter]} for #{param[:tool]} (#{param[:description]})"
    end.join("\n")
    
    response = llm_chat.ask(<<~PROMPT)
      Generate a natural, friendly question to ask the user for this missing information:
      
      #{param_descriptions}
      
      Ask for the most important missing parameter first. Be conversational and helpful.
    PROMPT
    
    response.content
  end

  def classify_user_intent(user_message)
    llm_chat = RubyLLM.chat
    
    response = llm_chat.ask(<<~PROMPT)
      Classify this user message into one of these categories:
      - provide_param: User is providing a parameter value
      - cancel: User wants to cancel the current operation
      - new_topic: User is starting a new topic
      
      User message: "#{user_message}"
      
      Return only the category name.
    PROMPT
    
    response.content.downcase.strip.to_sym
  end

  def generate_response_with_partial_results(original_message, tool_results)
    llm_chat = RubyLLM.chat
    
    # Separate successful and failed results
    successful_results = tool_results.reject { |r| r[:error] }
    failed_results = tool_results.select { |r| r[:error] }
    
    context = successful_results.map do |result|
      "Tool #{result[:tool]} result: #{result[:content]}"
    end.join("\n")
    
    error_context = failed_results.map do |result|
      error_msg = result[:error]
      # Add helpful context for common path-related errors
      if error_msg.include?("Access denied") && error_msg.include?("allowed directories")
        error_msg += "\n\nNote: The available directories are /private/tmp. You can use 'list_allowed_directories' to see what's available."
      end
      "Tool #{result[:tool]} failed: #{error_msg}"
    end.join("\n")
    
    prompt = <<~PROMPT
      Original user message: "#{original_message}"
      
      #{context}
      
      #{error_context}
      
      Please provide a helpful response using the available information. 
      If some information is missing due to tool failures, acknowledge it but provide the best answer possible.
      If there are path-related errors, suggest the correct paths or available directories.
      Be natural and conversational.
    PROMPT
    
    response = llm_chat.ask(prompt)
    response.content
  end

  private

  def collect_all_tools
    tools = []
    @mcp_clients.each do |client|
      begin
        # Check if client is alive and has tools capability
        next unless client.respond_to?(:alive?) && client.alive?
        next unless client.respond_to?(:capabilities) && client.capabilities.tools_list?
        
        client_tools = client.tools
        tools.concat(client_tools) if client_tools && client_tools.any?
      rescue => e
        Rails.logger.error "Failed to get tools from MCP client #{client.name}: #{e.message}"
      end
    end
    tools
  end

  def execute_single_tool(tool_call, collected_params)
    # Find the MCP client that has this tool
    client = find_client_with_tool(tool_call[:name])
    return { tool: tool_call[:name], error: "Tool not found" } unless client
    
    tool = client.tool(tool_call[:name])
    return { tool: tool_call[:name], error: "Tool not available" } unless tool
    
    # Prepare parameters
    parameters = tool_call[:parameters] || {}
    parameters.merge!(collected_params)
    
    result = tool.execute(**parameters)
    
    # Handle the result based on the tool's response format
    if result.is_a?(Hash) && result[:error]
      { tool: tool_call[:name], error: result[:error] }
    elsif result.respond_to?(:text)
      { tool: tool_call[:name], content: result.text }
    else
      { tool: tool_call[:name], content: result.to_s }
    end
  rescue => e
    { tool: tool_call[:name], error: e.message }
  end

  def find_client_with_tool(tool_name)
    @mcp_clients.find do |client|
      begin
        next unless client.respond_to?(:alive?) && client.alive?
        next unless client.respond_to?(:capabilities) && client.capabilities.tools_list?
        
        client.tools.any? { |tool| tool.name == tool_name }
      rescue
        false
      end
    end
  end

  def chain_output_to_next_tool(result, next_tool, collected_params)
    # This is a simplified implementation
    # In practice, you'd need more sophisticated output mapping
    if result[:content] && !result[:error]
      # Add the result to collected params for the next tool
      collected_params["previous_tool_output"] = result[:content]
    end
  end
end
