# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::UsersAccountTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/users/account" do
    put("Update My Account") do
      operationId "updateAccount"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/AccountUpdateInput"}
      parameter name: "X-Access-Confirmation", in: :header, schema: {type: :string},
        description: "Access confirmation token obtained from confirm-access endpoint. Required when using OAuth/OpenID authentication.",
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/User"
      end

      response(400, "bad request") do
        schema "$ref" => "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  def confirm_access!(password)
    post confirm_access_api_v1_sessions_path, params: {password: password}, as: :json
  end

  test "PUT /users/account updates account" do
    user = create(:user, password: "enterprise")
    sign_in user
    confirm_access!("enterprise")

    assert_api_response :put, 200, body: {username: "TestUser"} do
      assert_equal "TestUser", parsed_body["username"]
    end
  end

  test "PUT /users/account returns 400 for invalid input" do
    user = create(:user, password: "enterprise")
    sign_in user
    confirm_access!("enterprise")

    assert_api_response :put, 400, body: {username: ""}
  end

  test "PUT /users/account returns 401 when not signed in" do
    assert_api_response :put, 401, body: {username: "TestUser"}
  end
end
