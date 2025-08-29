require 'ruby_llm'

class ChatService
  def self.generate_response(chat, user_message, mcp_clients = nil)
    # If we have MCP clients, use the new conversation flow
    if mcp_clients&.any?
      conversation_manager = ConversationManager.new(chat)
      result = conversation_manager.process_message(user_message)
      
      case result[:type]
      when :clarification, :final_response
        # Both are normal assistant messages
        assistant_message = chat.messages.create!(
          content: result[:content],
          role: 'assistant'
        )
        return { 
          success: true, 
          message: assistant_message 
        }
        
      when :cancelled, :error
        # Both are system messages
        system_message = chat.messages.create!(
          content: result[:content],
          role: 'system'
        )
        return { 
          success: false, 
          message: system_message 
        }
      end
    else
      # Fall back to current simple implementation
      generate_simple_response(chat, user_message)
    end
  end

  def self.generate_simple_response(chat, user_message)
    begin
      # Use RubyLLM with the default model from the configured provider
      llm_chat = RubyLLM.chat
      response = llm_chat.ask(user_message)
      
      # Create the assistant message
      assistant_message = chat.messages.create!(
        content: response.content,
        role: 'assistant',
        prompt_tokens: response.input_tokens,
        completion_tokens: response.output_tokens,
        total_tokens: (response.input_tokens || 0) + (response.output_tokens || 0),
        usage_data: {
          'prompt_tokens' => response.input_tokens,
          'completion_tokens' => response.output_tokens,
          'total_tokens' => (response.input_tokens || 0) + (response.output_tokens || 0)
        }
      )
      
      {
        message: assistant_message,
        success: true
      }
    rescue => e
      Rails.logger.error "Error generating response: #{e.message}"
      
      # Create a system message for the error
      system_message = chat.messages.create!(
        content: "⚠️ Unable to generate a response at this time. Please try again later.",
        role: 'system'
      )
      
      {
        message: system_message,
        error: true
      }
    end
  end

  def self.generate_title(chat, mcp_client = nil)
    messages = chat.messages.order(:created_at)
    return "New Chat" if messages.empty?
    
    message_count = messages.count
    
    if message_count == 1
      # First message - just truncate the user's message
      first_message = messages.first
      content = first_message.content
      if content.length > 50
        "#{content[0..47]}..."
      else
        content
      end
    elsif message_count == 4
      # 4th message - ask LLM to create a summary title
      begin
        conversation_context = messages.limit(4).map do |msg|
          "#{msg.role}: #{msg.content}"
        end.join("\n")
        
        llm_chat = RubyLLM.chat
        
        # Add MCP tools, resources, and prompts if provided
        if mcp_client
          # Add available tools
          tools = mcp_client.tools
          llm_chat.with_tools(*tools) if tools.any?
          
          # Add available resources
          resources = mcp_client.resources
          resources.each do |resource|
            llm_chat.with_resource(resource)
          end if resources.any?
          
          # Add available resource templates
          templates = mcp_client.resource_templates
          templates.each do |template|
            llm_chat.with_resource_template(template)
          end if templates.any?
          
          # Add available prompts
          prompts = mcp_client.prompts
          prompts.each do |prompt|
            llm_chat.with_prompt(prompt)
          end if prompts.any?
        end
        
        title = llm_chat.ask("Generate a short, descriptive title (max 50 characters) for this conversation:\n\n#{conversation_context}").content.strip
        
        # Update the chat title
        chat.update!(title: title) if title.present? && title.length <= 50
        
        title
      rescue => e
        Rails.logger.error "Error generating title with LLM: #{e.message}"
        # Fallback to first message content
        first_message = messages.first
        content = first_message.content
        if content.length > 50
          "#{content[0..47]}..."
        else
          content
        end
      end
    else
      # For other message counts, return the current title
      chat.title
    end
  end

  def self.create_chat_for_user(user, title = nil)
    chat = user.chats.create!(
      title: title || "New Chat",
      status: 'active'
    )
    
    # Add a welcome message
    chat.messages.create!(
      content: "Hello! I'm your AI assistant. How can I help you today?",
      role: 'assistant'
    )
    
    chat
  end

  def self.archive_chat(chat)
    chat.update!(status: 'archived')
  end

  def self.report_chat(chat)
    chat.update!(status: 'reported')
  end

  def self.delete_chat(chat)
    chat.destroy
  end
  
  # Usage aggregation methods
  def self.get_chat_usage(chat)
    messages = chat.messages.assistant_messages.with_usage
    
    {
      total_messages: messages.count,
      total_tokens: messages.sum(:total_tokens),
      prompt_tokens: messages.sum(:prompt_tokens),
      completion_tokens: messages.sum(:completion_tokens),
      estimated_cost: 0 # TODO: Implement cost calculation
    }
  end
  
  def self.get_user_usage(user, time_period = nil)
    scope = user.chats.joins(:messages).where(messages: { role: :assistant })
    scope = scope.where('messages.created_at >= ?', time_period) if time_period
    
    messages = scope.select('messages.*')
    
    {
      total_chats: user.chats.count,
      total_messages: messages.count,
      total_tokens: messages.sum(:total_tokens),
      prompt_tokens: messages.sum(:prompt_tokens),
      completion_tokens: messages.sum(:completion_tokens),
      estimated_cost: 0 # TODO: Implement cost calculation
    }
  end
end
