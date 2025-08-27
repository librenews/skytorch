class DashboardController < ApplicationController
  def index
    @providers = current_user.using_global_provider? ? Provider.global : current_user.providers
    @chats = current_user.chats.active.order(updated_at: :desc).limit(10)
  end

  def connection_status
    provider = current_user.default_provider
    
    if provider
      render json: {
        status: 'connected',
        provider: provider.name,
        provider_type: provider.provider_type
      }
    else
      render json: { status: 'disconnected' }
    end
  end

  def load_more_chats
    page = params[:page]&.to_i || 1
    per_page = 10
    
    @chats = current_user.chats.active
      .order(updated_at: :desc)
      .offset((page - 1) * per_page)
      .limit(per_page)
    
    render partial: 'chat_list', locals: { chats: @chats }
  end

  def update_chat_status
    chat = current_user.chats.find(params[:id])
    new_status = params[:status]
    
    if %w[active archived reported].include?(new_status)
      chat.update!(status: new_status)
      render json: { success: true, status: new_status }
    else
      render json: { success: false, error: 'Invalid status' }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Chat not found' }, status: :not_found
  end
end
