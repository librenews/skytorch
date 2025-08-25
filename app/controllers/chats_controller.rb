class ChatsController < ApplicationController
  before_action :authenticate_user!
  def index
    @chats = current_user.chats.order(created_at: :desc)
    
    respond_to do |format|
      format.html
      format.json { render json: @chats.map { |chat| { 
        id: chat.id, 
        title: chat.title, 
        message_count: chat.messages.count,
        created_at: chat.created_at
      }}}
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @messages = @chat.messages.order(:created_at)
    
    respond_to do |format|
      format.html
      format.json { render json: { 
        id: @chat.id, 
        title: @chat.title, 
        messages: @messages.map { |m| { id: m.id, role: m.role, content: m.content, created_at: m.created_at } }
      }}
    end
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = current_user.chats.build(chat_params)
    
    if @chat.save
      respond_to do |format|
        format.html { redirect_to @chat, notice: 'Chat was successfully created.' }
        format.json { render json: @chat }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @chat.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    
    if @chat.destroy
      respond_to do |format|
        format.html { redirect_to chats_path, notice: 'Chat was successfully deleted.' }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @chat, alert: 'Failed to delete chat.' }
        format.json { render json: { errors: @chat.errors }, status: :unprocessable_entity }
      end
    end
  end
  
  private
  
  def chat_params
    params.require(:chat).permit(:title)
  end
end
