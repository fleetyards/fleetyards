# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UsersSignupTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/users/signup" do
    post("Create new User") do
      operationId "signup"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/UserCreateInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/User"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(422, "unprocessable entity") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  def signup_body(**overrides)
    {
      username: "TestUser",
      email: "test@fleetyards.net",
      password: "password",
      passwordConfirmation: "password",
      saleNotify: true,
      fleetInviteToken: "ee86f1f1dbb8799dcb6f5cb9efd73f"
    }.merge(overrides)
  end

  test "POST /users/signup creates a new user" do
    assert_api_response :post, 201, body: signup_body
  end

  test "POST /users/signup returns 400 when email is taken" do
    create(:user, email: "test@fleetyards.net")

    assert_api_response :post, 400, body: signup_body
  end

  test "POST /users/signup returns 422 when already signed in" do
    sign_in create(:user)

    assert_api_response :post, 422, body: signup_body
  end
end
