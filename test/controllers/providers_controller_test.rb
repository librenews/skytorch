require "test_helper"

class ProvidersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get providers_index_url
    assert_response :success
  end

  test "should get create" do
    get providers_create_url
    assert_response :success
  end

  test "should get update" do
    get providers_update_url
    assert_response :success
  end

  test "should get destroy" do
    get providers_destroy_url
    assert_response :success
  end
end
