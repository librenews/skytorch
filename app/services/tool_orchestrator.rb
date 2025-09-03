class ToolOrchestrator
  def initialize(mcp_clients)
    @mcp_clients = mcp_clients
  end

  def detect_required_tools(user_message)
    # Get all available tools from all clients
    all_tools = collect_all_tools
    
    if all_tools.empty?
      Rails.logger.info "No tools available from MCP clients"
      return []
    end

    # Create a simple tool list for the LLM to analyze
    tool_list = all_tools.map do |tool|
      {
        name: tool.name,
        description: tool.description || "No description available"
      }
    end

    # Ask LLM which tool(s) are needed
    llm_chat = RubyLLM.chat
    response = llm_chat.ask(<<~PROMPT)
      Analyze this user message and determine which tools are needed.
      
      Available tools:
      #{tool_list.map { |t| "- #{t[:name]}: #{t[:description]}" }.join("\n")}
      
      User message: "#{user_message}"
      
      Return a JSON array of tool names that are needed. If no tools are needed, return an empty array.
      Example: ["list_directory"] or []
      
      Only return the JSON array, nothing else.
    PROMPT

    # Parse the response
    begin
      tool_names = parse_tool_response(response.content)
      Rails.logger.info "LLM detected tools: #{tool_names}"
      
      # Find the actual tool objects
      detected_tools = all_tools.select { |tool| tool_names.include?(tool.name) }
      Rails.logger.info "Found #{detected_tools.length} matching tools"
      
      detected_tools
    rescue => e
      Rails.logger.error "Failed to parse LLM response: #{response.content}"
      Rails.logger.error "Error: #{e.message}"
      []
    end
  end

  def check_missing_parameters(tools, collected_params = {})
    missing_params = []
    
    tools.each do |tool|
      # Get the tool's required parameters
      input_schema = tool.instance_variable_get(:@input_schema)
      required_fields = input_schema&.dig('required') || []
      
      required_fields.each do |param_name|
        # Check if parameter is already collected
        param_provided = collected_params.key?(param_name.to_s) || collected_params.key?(param_name.to_sym)
        
        unless param_provided
          # Find parameter description
          param = tool.parameters&.[](param_name)
          description = param&.description || param_name
          
          missing_params << {
            tool: tool.name,
            parameter: param_name,
            description: description
          }
        end
      end
    end
    
    missing_params
  end

  def generate_clarification_question(missing_params)
    return nil if missing_params.empty?
    
    # For now, just ask for the first missing parameter
    param = missing_params.first
    "I need the #{param[:description]} for the #{param[:tool]} tool. Could you please provide it?"
  end

  def execute_tool_chain(tool_calls, collected_params)
    results = []
    
    tool_calls.each do |tool_call|
      tool_name = tool_call[:name]
      parameters = tool_call[:parameters] || {}
      
      # Find the tool
      tool = find_tool_by_name(tool_name)
      unless tool
        results << {
          tool: tool_name,
          error: "Tool not found: #{tool_name}",
          content: nil
        }
        next
      end
      
      # Merge collected parameters with tool call parameters
      merged_params = collected_params.merge(parameters)
      
      # Execute the tool
      result = execute_single_tool(tool, merged_params)
      results << result
    end
    
    results
  end

  def generate_response_with_results(results, original_message)
    successful_results = results.select { |r| !r[:error] }
    failed_results = results.select { |r| r[:error] }
    
    if successful_results.empty?
      return "I encountered some issues while trying to help you. Please try again or let me know if you need assistance with something else."
    end
    
    # For now, just return the first successful result
    result = successful_results.first
    content = result[:content]
    
    if content.is_a?(String)
      return content
    elsif content.is_a?(Array) && content.any?
      # Handle array of content items
      return content.map { |item| item.text || item.content }.join("\n")
    elsif content.respond_to?(:text)
      # Handle RubyLLM::MCP::Content objects
      return content.text
    else
      return "I completed the requested operation. Let me know if you need anything else!"
    end
  end

  private

  def collect_all_tools
    all_tools = []
    
    @mcp_clients.each do |client|
      next unless client.respond_to?(:alive?) && client.alive?
      next unless client.respond_to?(:capabilities) && client.capabilities.tools_list?
      
      begin
        tools = client.tools
        all_tools.concat(tools) if tools
      rescue => e
        Rails.logger.error "Failed to get tools from client: #{e.message}"
      end
    end
    
    all_tools
  end

  def find_tool_by_name(tool_name)
    all_tools = collect_all_tools
    all_tools.find { |tool| tool.name == tool_name }
  end

  def execute_single_tool(tool, parameters)
    begin
      Rails.logger.info "Executing tool: #{tool.name} with parameters: #{parameters}"
      
      # Execute the tool
      result = tool.execute(**parameters)
      
      Rails.logger.info "Tool execution successful: #{tool.name}"
      
      {
        tool: tool.name,
        content: result,
        error: nil
      }
    rescue => e
      Rails.logger.error "Tool execution failed: #{tool.name} - #{e.message}"
      
      {
        tool: tool.name,
        content: nil,
        error: e.message
      }
    end
  end

  def parse_tool_response(response_content)
    content = response_content.strip
    
    # Case 1: Raw JSON array
    if content.start_with?('[') && content.end_with?(']')
      begin
        return JSON.parse(content)
      rescue JSON::ParserError
        # Continue to next case
      end
    end
    
    # Case 2: Markdown code block with JSON
    if content.start_with?('```') && content.end_with?('```')
      json_content = content.gsub(/^```\w*\n/, '').gsub(/\n```$/, '').strip
      if json_content.start_with?('[') && json_content.end_with?(']')
        begin
          return JSON.parse(json_content)
        rescue JSON::ParserError
          # Continue to next case
        end
      end
    end
    
    # Case 3: Single tool name (no brackets, just the name)
    if content.match?(/^[a-z_]+$/)
      return [content]
    end
    
    # Case 4: Natural language - try to extract tool names
    return extract_tools_from_natural_language(content)
  end

  def extract_tools_from_natural_language(content)
    # Look for tool names in the text
    all_tools = collect_all_tools
    available_tool_names = all_tools.map(&:name)
    found_tools = []
    
    available_tool_names.each do |tool_name|
      if content.downcase.include?(tool_name.downcase)
        found_tools << tool_name
      end
    end
    
    found_tools
  end
end
