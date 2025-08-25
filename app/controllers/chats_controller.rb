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

  def update
    @chat = current_user.chats.find(params[:id])
    
    if @chat.update(chat_params)
      respond_to do |format|
        format.html { redirect_to @chat, notice: 'Chat was successfully updated.' }
        format.json { render json: @chat }
      end
    else
      respond_to do |format|
        format.html { redirect_to @chat, alert: 'Failed to update chat.' }
        format.json { render json: { errors: @chat.errors }, status: :unprocessable_entity }
      end
    end
  end

  def generate_title
    @chat = current_user.chats.find(params[:id])
    user_message = params[:user_message]
    ai_response = params[:ai_response]
    
    # Create a simple title based on the user's message
    # In a more sophisticated implementation, you could use AI to generate a better title
    title = user_message.length > 50 ? user_message[0..50] + '...' : user_message
    
    if @chat.update(title: title)
      respond_to do |format|
        format.json { render json: { title: title } }
      end
    else
      respond_to do |format|
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
