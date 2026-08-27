# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UsersCheckEmailTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/users/check-email" do
    post("Check E-Mail Availability") do
      operationId "checkEmail"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::CheckInput

      response(200, "successful") do
        schema ::V1::Schemas::Check
      end
    end
  end

  test "POST /users/check-email reports the email as taken" do
    create(:user, email: "test@fleetyards.dev")

    assert_api_response :post, 200, body: {value: "test@fleetyards.dev"} do
      assert_equal true, parsed_body["taken"]
    end
  end

  test "POST /users/check-email reports availability" do
    assert_api_response :post, 200, body: {value: "fresh@fleetyards.dev"} do
      assert_equal false, parsed_body["taken"]
    end
  end
end
