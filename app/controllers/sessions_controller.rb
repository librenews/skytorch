class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:omniauth]
  skip_before_action :authenticate_user!, only: [:omniauth, :failure]

  def omniauth
    auth = request.env['omniauth.auth']
    
    Rails.logger.info "OAuth callback received: #{auth.inspect}"
    
    if auth && auth.info.did
      Rails.logger.info "Auth DID: #{auth.info.did}"
      Rails.logger.info "Auth info: #{auth.info.inspect}"
      
      # Find or create user based on Bluesky DID
      user = User.find_or_initialize_by(bluesky_did: auth.info.did)
      
      # Update user information from OAuth response
      # For AT Protocol, we use the DID as the identifier
      user.bluesky_handle = auth.info.did
      user.display_name = auth.info.did.split(':').last || auth.info.did
      user.avatar_url = nil # AT Protocol doesn't provide avatar in OAuth response
      
      # Try to fetch profile information using AT Protocol service
      begin
        at_service = AtProtocolService.new
        profile_data = at_service.get_profile(auth.info.did)
        
        if profile_data && profile_data[:handle]
          # Update the user's profile cache with fresh data
          user.update_profile_cache!(profile_data)
        end
      rescue => e
        Rails.logger.warn "Failed to fetch AT Protocol profile: #{e.message}"
      end
      
      Rails.logger.info "User before save: #{user.attributes.inspect}"
      Rails.logger.info "User valid? #{user.valid?}"
      Rails.logger.info "User errors: #{user.errors.full_messages}" unless user.valid?
      
      if user.save
        session[:user_id] = user.id
        Rails.logger.info "User saved successfully, session[:user_id] = #{session[:user_id]}"
        redirect_to dashboard_path, notice: "Welcome back, #{user.display_name}!"
      else
        Rails.logger.error "Failed to save user: #{user.errors.full_messages.join(', ')}"
        redirect_to login_path, alert: "Failed to save user information: #{user.errors.full_messages.join(', ')}"
      end
    else
      Rails.logger.error "No auth data received"
      redirect_to login_path, alert: "Authentication failed. Please try again."
    end
  end

  def failure
    error_message = params[:message] || "Authentication failed"
    redirect_to login_path, alert: "Login failed: #{error_message}"
  end
  
  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "You have been logged out successfully."
  end
  
  private

end
