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
      
      # Use ChatService to process the message with LLM and MCP
      chat_service = ChatService.new(@chat)
      result = chat_service.send_message(@message.content)
      
      respond_to do |format|
        format.html { redirect_to @chat, notice: 'Message sent successfully.' }
        format.json { render json: { 
          success: true, 
          assistant_message: { 
            id: result[:message].id, 
            role: result[:message].role, 
            content: result[:message].content, 
            created_at: result[:message].created_at 
          },
          rate_limits: result[:rate_limits]
        }}
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
end
