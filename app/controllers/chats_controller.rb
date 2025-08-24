class ChatsController < ApplicationController
  def index
    @chats = Chat.order(created_at: :desc)
  end

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.order(:created_at)
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = Chat.new(chat_params)
    
    if @chat.save
      redirect_to @chat, notice: 'Chat was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def chat_params
    params.require(:chat).permit(:title)
  end
end
