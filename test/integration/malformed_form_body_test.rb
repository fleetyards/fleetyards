# frozen_string_literal: true

require "test_helper"

class MalformedFormBodyTest < ActionDispatch::IntegrationTest
  test "a form field declared as UTF-16LE is a 400, not a 500" do
    body = [
      "--boundary",
      "Content-Disposition: form-data; name=\"user\"",
      "Content-Type: text/plain; charset=UTF-16LE",
      "",
      "value",
      "--boundary--",
      ""
    ].join("\r\n")

    post "/users/sign_in", params: body, headers: {"CONTENT_TYPE" => "multipart/form-data; boundary=boundary"}

    assert_response :bad_request
  end
end
