require "test_helper"

class AtProtocolServiceTest < ActiveSupport::TestCase
  def setup
    # Skip full initialization for now, just test the service structure
  end

  def teardown
  end

  test "service class exists and has expected methods" do
    # Test that the service class exists and has the expected methods
    assert defined?(AtProtocolService)
    
    # Test that the service has the expected instance methods
    service_methods = AtProtocolService.instance_methods(false)
    expected_methods = [
      :get_profile, :create_session, :create_post, :get_timeline,
      :search_users, :get_user_posts, :like_post, :unlike_post,
      :repost, :delete_repost, :follow_user, :unfollow_user,
      :get_followers, :get_following
    ]
    
    expected_methods.each do |method|
      assert_includes service_methods, method, "AtProtocolService should have method: #{method}"
    end
  end


end
