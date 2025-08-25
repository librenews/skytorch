require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include Minitest::Mock
  def setup
    @user = users(:one)
    @profile_data = {
      handle: 'test.user',
      display_name: 'Test User',
      avatar_url: 'https://example.com/avatar.jpg',
      description: 'Test description',
      did: 'did:plc:test123',
      followers_count: 100,
      following_count: 50,
      posts_count: 25,
      indexed_at: '2023-01-01T00:00:00Z',
      viewer: { 'following' => false }
    }
  end

  test "omniauth creates new user with profile data" do
    auth_hash = {
      'info' => {
        'did' => 'did:plc:newuser123'
      }
    }

    mock_service = Minitest::Mock.new
    mock_service.expect :get_profile, @profile_data, ['did:plc:newuser123']

    AtProtocolService.stub :new, mock_service do
      post "/auth/atproto/callback", params: {}, env: { 'omniauth.auth' => auth_hash }
    end

    assert_redirected_to dashboard_path
    assert_equal "Welcome back, Test User!", flash[:notice]
    
    user = User.find_by(bluesky_did: 'did:plc:newuser123')
    assert_not_nil user
    assert_equal 'test.user', user.bluesky_handle
    assert_equal 'Test User', user.display_name
    assert_equal 'https://example.com/avatar.jpg', user.avatar_url
    assert_equal @profile_data, user.profile_cache
    assert_not_nil user.profile_updated_at

    mock_service.verify
  end

  test "omniauth updates existing user with fresh profile data" do
    auth_hash = {
      'info' => {
        'did' => @user.bluesky_did
      }
    }

    mock_service = Minitest::Mock.new
    mock_service.expect :get_profile, @profile_data, [@user.bluesky_did]

    AtProtocolService.stub :new, mock_service do
      post "/auth/atproto/callback", params: {}, env: { 'omniauth.auth' => auth_hash }
    end

    assert_redirected_to dashboard_path
    assert_equal "Welcome back, Test User!", flash[:notice]
    
    @user.reload
    assert_equal 'test.user', @user.bluesky_handle
    assert_equal 'Test User', @user.display_name
    assert_equal 'https://example.com/avatar.jpg', @user.avatar_url
    assert_equal @profile_data, @user.profile_cache
    assert_not_nil @user.profile_updated_at

    mock_service.verify
  end

  test "omniauth handles API errors gracefully" do
    auth_hash = {
      'info' => {
        'did' => 'did:plc:newuser123'
      }
    }

    mock_service = Minitest::Mock.new
    mock_service.expect :get_profile, nil, ['did:plc:newuser123']

    AtProtocolService.stub :new, mock_service do
      post "/auth/atproto/callback", params: {}, env: { 'omniauth.auth' => auth_hash }
    end

    assert_redirected_to dashboard_path
    assert_equal "Welcome back, newuser123!", flash[:notice]
    
    user = User.find_by(bluesky_did: 'did:plc:newuser123')
    assert_not_nil user
    assert_equal 'did:plc:newuser123', user.bluesky_handle
    assert_equal 'newuser123', user.display_name

    mock_service.verify
  end

  test "omniauth handles missing auth data" do
    post "/auth/atproto/callback", params: {}

    assert_redirected_to login_path
    assert_equal "Authentication failed. Please try again.", flash[:alert]
  end

  test "omniauth handles missing DID" do
    auth_hash = {
      'info' => {}
    }

    post "/auth/atproto/callback", params: {}, env: { 'omniauth.auth' => auth_hash }

    assert_redirected_to login_path
    assert_equal "Authentication failed. Please try again.", flash[:alert]
  end

  test "omniauth handles user save errors" do
    auth_hash = {
      'info' => {
        'did' => @user.bluesky_did
      }
    }

    # Force a validation error by making the handle nil
    @user.update_column(:bluesky_handle, nil)

    mock_service = Minitest::Mock.new
    mock_service.expect :get_profile, @profile_data, [@user.bluesky_did]

    AtProtocolService.stub :new, mock_service do
      post "/auth/atproto/callback", params: {}, env: { 'omniauth.auth' => auth_hash }
    end

    assert_redirected_to login_path
    assert_includes flash[:alert], "Failed to save user information"

    mock_service.verify
  end

  test "failure redirects to login with error message" do
    get "/auth/failure", params: { message: "Access denied" }

    assert_redirected_to login_path
    assert_equal "Login failed: Access denied", flash[:alert]
  end

  test "failure uses default message when none provided" do
    get "/auth/failure"

    assert_redirected_to login_path
    assert_equal "Login failed: Authentication failed", flash[:alert]
  end

  test "destroy logs out user" do
    # Simulate logged in user
    session[:user_id] = @user.id

    delete "/sign_out"

    assert_redirected_to login_path
    assert_equal "You have been logged out successfully.", flash[:notice]
    assert_nil session[:user_id]
  end

  test "destroy with GET request also works" do
    # Simulate logged in user
    session[:user_id] = @user.id

    get "/sign_out"

    assert_redirected_to login_path
    assert_equal "You have been logged out successfully.", flash[:notice]
    assert_nil session[:user_id]
  end

  test "omniauth sets session correctly" do
    auth_hash = {
      'info' => {
        'did' => 'did:plc:newuser123'
      }
    }

    mock_service = Minitest::Mock.new
    mock_service.expect :get_profile, @profile_data, ['did:plc:newuser123']

    AtProtocolService.stub :new, mock_service do
      post "/auth/atproto/callback", params: {}, env: { 'omniauth.auth' => auth_hash }
    end

    user = User.find_by(bluesky_did: 'did:plc:newuser123')
    assert_equal user.id, session[:user_id]

    mock_service.verify
  end

  test "omniauth handles profile data with missing handle" do
    auth_hash = {
      'info' => {
        'did' => 'did:plc:newuser123'
      }
    }

    profile_data_without_handle = @profile_data.except(:handle)
    mock_service = Minitest::Mock.new
    mock_service.expect :get_profile, profile_data_without_handle, ['did:plc:newuser123']

    AtProtocolService.stub :new, mock_service do
      post "/auth/atproto/callback", params: {}, env: { 'omniauth.auth' => auth_hash }
    end

    assert_redirected_to dashboard_path
    assert_equal "Welcome back, newuser123!", flash[:notice]
    
    user = User.find_by(bluesky_did: 'did:plc:newuser123')
    assert_not_nil user
    assert_equal 'did:plc:newuser123', user.bluesky_handle
    assert_equal 'newuser123', user.display_name

    mock_service.verify
  end
end
