class MessagesController < ApplicationController
  before_action :set_chat
  
    def create
    @message = @chat.messages.build(message_params.merge(role: 'user'))
    
    if @message.save
      # Update chat title on first message
      if @chat.messages.count == 1
        title = @message.content.length > 100 ? @message.content[0..100] + '...' : @message.content
        @chat.update(title: title)
      end
      
      # Get MCP client if available
      mcp_client = get_mcp_client
      
      # Use ChatService to process the message with LLM
      result = ChatService.generate_response(@chat, @message.content, mcp_client)
      
      respond_to do |format|
        format.html { redirect_to @chat, notice: 'Message sent successfully.' }
        format.json { 
          if result[:error]
            render json: { 
              success: false, 
              system_message: { 
                id: result[:message].id, 
                role: result[:message].role, 
                content: result[:message].content, 
                created_at: result[:message].created_at 
              }
            }
          else
            render json: { 
              success: true, 
              assistant_message: { 
                id: result[:message].id, 
                role: result[:message].role, 
                content: result[:message].content, 
                created_at: result[:message].created_at 
              },
              rate_limits: result[:rate_limits]
            }
          end
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to @chat, alert: 'Failed to send message.' }
        format.json { render json: { errors: @message.errors }, status: :unprocessable_entity }
      end
    end
  end
  
  private
  
  def set_chat
    @chat = Chat.find(params[:chat_id])
  end
  
  def message_params
    params.require(:message).permit(:content)
  end
  
  def get_mcp_client
    # For now, return nil. In the future, this could be:
    # - Stored in the chat model
    # - Retrieved from user preferences
    # - Created based on chat context
    # - Retrieved from a global MCP client manager
    
    # Example implementation:
    # return nil unless @chat.mcp_server_url.present?
    # 
    # RubyLLM::MCP.client(
    #   name: "chat-#{@chat.id}",
    #   transport_type: :streamable,
    #   config: {
    #     url: @chat.mcp_server_url,
    #     headers: { "Authorization" => "Bearer #{@chat.mcp_auth_token}" }
    #   }
    # )
    
    nil
  end
end
