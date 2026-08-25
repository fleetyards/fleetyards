# frozen_string_literal: true

require "test_helper"

# The docs catch-all answers every verb and format. A 406 that kept the
# requested JavaScript content type made Rails' same-origin verification raise
# InvalidCrossOriginRequest, turning a refused embed into a reported error.
class DocsCrossOriginTest < ActionDispatch::IntegrationTest
  test "a cross-origin script request is refused as plain text" do
    get "/docs/api.js", headers: {"HTTP_ORIGIN" => "https://embedder.test"}

    assert_response :not_acceptable
    assert_equal "text/plain", response.media_type
  end
end
