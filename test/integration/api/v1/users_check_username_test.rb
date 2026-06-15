# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UsersCheckUsernameTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/users/check-username" do
    post("Check Username Availability") do
      operationId "checkUsername"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/CheckInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"
      end
    end
  end

  test "POST /users/check-username reports the username as taken" do
    create(:user, username: "data")

    assert_api_response :post, 200, body: {value: "data"} do
      assert_equal true, parsed_body["taken"]
    end
  end

  test "POST /users/check-username reports availability" do
    assert_api_response :post, 200, body: {value: "fresh-username"} do
      assert_equal false, parsed_body["taken"]
    end
  end
end
