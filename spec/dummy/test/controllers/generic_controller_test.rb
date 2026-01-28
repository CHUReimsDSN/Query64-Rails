require "test_helper"

class GenericControllerTest < ActionDispatch::IntegrationTest
  test "Query64 GetMetadata" do
    url = "/api/get-metadata-query64"

    # Regular
    payload = {
      query64Params: {
        resourceName: "Article",
      }
    }
    post(url, params: payload)
    assert_response :success

  end

  test "Query64 GetRows" do
    url = "/api/get-rows-query64"

    # Regular
    payload = {
      query64Params: {
        resourceName: "Article",
      }
    }
    post(url, params: payload)
    assert_response :success

  end

  test "Query64 Export" do
    url = "/api/export-rows-query64"

    # Regular
    payload = {
      query64Params: {
        resourceName: "Article",
      }
    }
    post(url, params: payload)
    assert_response :success
  end

end
