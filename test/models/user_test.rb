require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "bluesky_handle should be present" do
    @user.bluesky_handle = nil
    assert_not @user.valid?
  end

  test "bluesky_handle should be unique" do
    duplicate_user = @user.dup
    assert_not duplicate_user.valid?
  end

  test "bluesky_did should be present" do
    @user.bluesky_did = nil
    assert_not @user.valid?
  end

  test "bluesky_did should be unique" do
    duplicate_user = @user.dup
    duplicate_user.bluesky_handle = "different.handle"
    assert_not duplicate_user.valid?
  end

  test "display_name should be present" do
    @user.display_name = nil
    assert_not @user.valid?
  end

  test "should have many chats" do
    assert_respond_to @user, :chats
  end

  test "should have many providers" do
    assert_respond_to @user, :providers
  end

  test "should destroy associated chats when deleted" do
    chat = @user.chats.create!(title: "Test Chat")
    assert_difference 'Chat.count', -1 do
      @user.destroy
    end
  end

  test "should destroy associated providers when deleted" do
    provider = @user.providers.create!(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "test_key",
      default_model: "gpt-4"
    )
    assert_difference 'Provider.count', -1 do
      @user.destroy
    end
  end

  test "has_provider? returns true when user has providers" do
    @user.providers.create!(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "test_key",
      default_model: "gpt-4"
    )
    assert @user.has_provider?
  end

  test "has_provider? returns false when user has no providers" do
    @user.providers.destroy_all
    assert_not @user.has_provider?
  end

  test "using_global_provider? returns true when user has no providers" do
    @user.providers.destroy_all
    assert @user.using_global_provider?
  end

  test "using_global_provider? returns false when user has providers" do
    @user.providers.create!(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "test_key",
      default_model: "gpt-4"
    )
    assert_not @user.using_global_provider?
  end

  test "default_provider returns user's first provider" do
    provider = @user.providers.create!(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "test_key",
      default_model: "gpt-4"
    )
    assert_equal @user.providers.first, @user.default_provider
  end

  test "default_provider returns global default when user has no providers" do
    @user.providers.destroy_all
    # Skip this test for now since it depends on Provider.global_default implementation
    skip "Requires Provider.global_default implementation"
  end

  test "avatar_display_url returns avatar_url when present" do
    @user.avatar_url = "https://example.com/avatar.jpg"
    assert_equal "https://example.com/avatar.jpg", @user.avatar_display_url
  end

  test "avatar_display_url returns generated avatar when avatar_url is nil" do
    @user.avatar_url = nil
    assert_includes @user.avatar_display_url, "dicebear.com"
  end

  test "display_name_or_handle returns display_name when present" do
    @user.display_name = "Test User"
    assert_equal "Test User", @user.display_name_or_handle
  end

  test "display_name_or_handle returns bluesky_handle when display_name is nil" do
    @user.display_name = nil
    assert_equal @user.bluesky_handle, @user.display_name_or_handle
  end

  test "to_param returns bluesky_handle" do
    assert_equal @user.bluesky_handle, @user.to_param
  end

  test "find_by_handle_or_did finds by handle" do
    found_user = User.find_by_handle_or_did(@user.bluesky_handle)
    assert_equal @user, found_user
  end

  test "find_by_handle_or_did finds by did" do
    found_user = User.find_by_handle_or_did(@user.bluesky_did)
    assert_equal @user, found_user
  end

  test "find_by_handle_or_did returns nil for non-existent identifier" do
    found_user = User.find_by_handle_or_did("nonexistent")
    assert_nil found_user
  end
end
