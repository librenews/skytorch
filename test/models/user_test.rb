require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should be valid with required attributes" do
    user = User.new(
      bluesky_did: 'did:plc:newuser123',
      bluesky_handle: 'new.user',
      display_name: 'New User'
    )
    assert user.valid?
  end

  test "should require bluesky_did" do
    user = User.new(
      bluesky_handle: 'test.user',
      display_name: 'Test User'
    )
    assert_not user.valid?
    assert_includes user.errors[:bluesky_did], "can't be blank"
  end

  test "should require bluesky_handle" do
    user = User.new(
      bluesky_did: 'did:plc:test123',
      display_name: 'Test User'
    )
    assert_not user.valid?
    assert_includes user.errors[:bluesky_handle], "can't be blank"
  end

  test "should require display_name" do
    user = User.new(
      bluesky_did: 'did:plc:test123',
      bluesky_handle: 'test.user'
    )
    assert_not user.valid?
    assert_includes user.errors[:display_name], "can't be blank"
  end

  test "should have unique bluesky_did" do
    duplicate_user = @user.dup
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:bluesky_did], "has already been taken"
  end

  test "should have unique bluesky_handle" do
    duplicate_user = @user.dup
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:bluesky_handle], "has already been taken"
  end

  test "has_provider? returns true when user has llm_providers" do
    # The fixture already has providers, so this should be true
    assert @user.has_provider?
  end

  test "has_provider? returns false when user has no llm_providers" do
    user_without_providers = users(:no_cache)
    assert_not user_without_providers.has_provider?
  end

  test "default_provider returns user's first provider" do
    assert_equal @user.llm_providers.first, @user.default_provider
  end

  test "default_provider returns global default when user has no providers" do
    user = users(:no_cache)
    # Skip this test for now since it depends on LlmProvider.global_default
    skip "Requires LlmProvider.global_default implementation"
  end

  test "using_global_provider? returns true when user has no providers" do
    user = users(:no_cache)
    assert user.using_global_provider?
  end

  test "using_global_provider? returns false when user has providers" do
    assert_not @user.using_global_provider?
  end

  test "avatar_display_url returns avatar_url when present" do
    @user.avatar_url = 'https://example.com/avatar.jpg'
    assert_equal 'https://example.com/avatar.jpg', @user.avatar_display_url
  end

  test "avatar_display_url returns generated avatar when avatar_url is nil" do
    @user.avatar_url = nil
    expected_url = "https://ui-avatars.com/api/?name=#{@user.display_name}&background=6366f1&color=fff"
    assert_equal expected_url, @user.avatar_display_url
  end

  test "avatar_display_url returns generated avatar when avatar_url is empty" do
    @user.avatar_url = ''
    expected_url = "https://ui-avatars.com/api/?name=#{@user.display_name}&background=6366f1&color=fff"
    assert_equal expected_url, @user.avatar_display_url
  end


end
