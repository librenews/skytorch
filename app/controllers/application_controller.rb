class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :authenticate_user!
  before_action :set_common_variables, if: :current_user
  
  private
  
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  
  def authenticate_user!
    unless current_user
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end
  
  def set_common_variables
    @chats = current_user.chats.active.order(updated_at: :desc).limit(10)
    @current_provider = current_user.default_provider
    @connection_status = if @current_provider
      { status: 'connected', provider: @current_provider.name, provider_type: @current_provider.provider_type }
    else
      { status: 'disconnected' }
    end
  end
  
  helper_method :current_user
end
