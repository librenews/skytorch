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
      
      # Try to fetch profile information using app password
      begin
        profile_response = fetch_atproto_profile_with_app_password(auth.info.did)
        
        if profile_response && profile_response['handle']
          user.bluesky_handle = profile_response['handle']
          user.display_name = profile_response['displayName'] || profile_response['handle']
          user.avatar_url = profile_response['avatar'] if profile_response['avatar']
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
  
  def fetch_atproto_profile_with_app_password(did)
    require 'net/http'
    require 'json'
    
    # Get app password from Rails credentials
    app_password = Rails.application.credentials.bluesky_app_password
    bluesky_handle = Rails.application.credentials.bluesky_handle
    
    return nil unless app_password && bluesky_handle
    
    Rails.logger.info "Creating Bluesky session with handle: #{bluesky_handle}"
    
    # Create session using app password
    session_response = create_bluesky_session(bluesky_handle, app_password)
    return nil unless session_response
    
    access_jwt = session_response['accessJwt']
    Rails.logger.info "Session created successfully, access JWT obtained"
    
    # Try to get the handle from the DID first
    handle = extract_handle_from_did(did)
    
    # Fetch profile using the handle (more reliable than DID)
    uri = URI("https://bsky.social/xrpc/app.bsky.actor.getProfile")
    uri.query = URI.encode_www_form({ actor: handle || did })
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 30
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_jwt}"
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'Skytorch/1.0'
    
    Rails.logger.info "Fetching profile for actor: #{handle || did} using app password"
    
    response = http.request(request)
    
    if response.code == '200'
      profile_data = JSON.parse(response.body)
      Rails.logger.info "Profile data: #{profile_data.inspect}"
      profile_data
    else
      Rails.logger.warn "Failed to fetch profile: #{response.code} - #{response.body}"
      # Try with DID if handle failed
      if handle && handle != did
        Rails.logger.info "Retrying with DID: #{did}"
        uri.query = URI.encode_www_form({ actor: did })
        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer #{access_jwt}"
        request['Content-Type'] = 'application/json'
        request['User-Agent'] = 'Skytorch/1.0'
        
        response = http.request(request)
        if response.code == '200'
          profile_data = JSON.parse(response.body)
          Rails.logger.info "Profile data (DID retry): #{profile_data.inspect}"
          profile_data
        else
          Rails.logger.warn "Failed to fetch profile with DID: #{response.code} - #{response.body}"
          nil
        end
      else
        nil
      end
    end
  rescue => e
    Rails.logger.warn "Error fetching AT Protocol profile with app password: #{e.message}"
    Rails.logger.warn "Backtrace: #{e.backtrace.first(5).join("\n")}"
    nil
  end
  
  def extract_handle_from_did(did)
    # Try to extract handle from DID if it's in the format did:plc:handle
    if did.start_with?('did:plc:')
      handle = did.split(':').last
      # If it looks like a handle (not too long, no special chars), return it
      if handle.length <= 20 && handle.match?(/^[a-zA-Z0-9._-]+$/)
        return handle
      end
    end
    nil
  end
  
  def create_bluesky_session(handle, password)
    require 'net/http'
    require 'json'
    
    uri = URI("https://bsky.social/xrpc/com.atproto.server.createSession")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 30
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'Skytorch/1.0'
    
    request.body = {
      identifier: handle,
      password: password
    }.to_json
    
    Rails.logger.info "Creating session for handle: #{handle}"
    
    response = http.request(request)
    
    if response.code == '200'
      session_data = JSON.parse(response.body)
      Rails.logger.info "Session created successfully"
      session_data
    else
      Rails.logger.warn "Failed to create session: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.warn "Error creating Bluesky session: #{e.message}"
    Rails.logger.warn "Backtrace: #{e.backtrace.first(5).join("\n")}"
    nil
  end

end
