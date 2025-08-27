class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:omniauth]
  skip_before_action :authenticate_user!, only: [:omniauth, :failure]
  skip_before_action :set_common_variables, only: [:omniauth, :failure]

  def omniauth
    auth = request.env['omniauth.auth']
    
    Rails.logger.info "OAuth callback received: #{auth.inspect}"
    Rails.logger.info "Auth info keys: #{auth.info.keys}" if auth&.info
    Rails.logger.info "Auth info: #{auth.info.inspect}" if auth&.info
    
    if auth && auth.info.did
      Rails.logger.info "Auth DID: #{auth.info.did}"
      Rails.logger.info "Auth handle: #{auth.info.handle}" if auth.info.respond_to?(:handle)
      Rails.logger.info "Auth display_name: #{auth.info.display_name}" if auth.info.respond_to?(:display_name)
      
      # Find or create user based on Bluesky DID
      user = User.find_or_initialize_by(bluesky_did: auth.info.did)
      Rails.logger.info "User found/created: #{user.persisted? ? 'found' : 'new'}"
      Rails.logger.info "User before update: #{user.attributes.inspect}"
      
      # Try to fetch profile information using AT Protocol service first
      begin
        Rails.logger.info "Attempting to fetch profile for DID: #{auth.info.did}"
        at_service = AtProtocolService.new
        profile_data = at_service.get_profile(auth.info.did)
        Rails.logger.info "Profile data received: #{profile_data.inspect}"
        
        if profile_data && profile_data[:handle]
          Rails.logger.info "Updating user with profile data"
          # Update the user's profile with fresh data
          user.update_profile_from_api!(profile_data)
        else
          Rails.logger.warn "No profile data or handle, using fallback"
          # Fallback to basic info if profile fetch fails
          user.bluesky_handle = auth.info.did
          user.display_name = auth.info.did.split(':').last || auth.info.did
          user.avatar_url = nil
        end
      rescue => e
        Rails.logger.warn "Failed to fetch AT Protocol profile: #{e.message}"
        Rails.logger.warn "Error backtrace: #{e.backtrace.first(5).join(', ')}"
        # Fallback to basic info if profile fetch fails
        user.bluesky_handle = auth.info.did
        user.display_name = auth.info.did.split(':').last || auth.info.did
        user.avatar_url = nil
      end
      
      Rails.logger.info "User after update: #{user.attributes.inspect}"
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
