require "test_helper"

class LlmProvidersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get llm_providers_index_url
    assert_response :success
  end

  test "should get create" do
    get llm_providers_create_url
    assert_response :success
  end

  test "should get update" do
    get llm_providers_update_url
    assert_response :success
  end

  test "should get destroy" do
    get llm_providers_destroy_url
    assert_response :success
  end
end
