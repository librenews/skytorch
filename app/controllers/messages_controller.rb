class MessagesController < ApplicationController
  before_action :set_chat
  
  def create
    @message = @chat.messages.build(message_params)
    
    if @message.save
      # Use ChatService to process the message with LLM and MCP
      chat_service = ChatService.new(@chat)
      response = chat_service.send_message(@message.content)
      
      respond_to do |format|
        format.html { redirect_to @chat, notice: 'Message sent successfully.' }
        format.json { render json: { 
          success: true, 
          assistant_message: { 
            id: response.id, 
            role: response.role, 
            content: response.content, 
            created_at: response.created_at 
          }
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
