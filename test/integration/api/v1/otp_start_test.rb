# frozen_string_literal: true

require "openapi_helper"

class Api::V1::OtpStartTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/otp/start" do
    post("Start OTP Setup") do
      operationId "startOtpSetup"
      tags "OTP"
      produces "application/json"

      parameter name: "X-Access-Confirmation", in: :header, schema: {type: :string},
        description: "Access confirmation token obtained from confirm-access endpoint. Required when using OAuth/OpenID authentication.",
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  def confirm_access!(password)
    post confirm_access_api_v1_sessions_path, params: {password: password}, as: :json
  end

  test "POST /otp/start returns the setup message" do
    user = create(:user, password: "testtest")
    sign_in user
    confirm_access!("testtest")

    assert_api_response :post, 200, body: {}
  end

  test "POST /otp/start returns 400 for wrong password" do
    user = create(:user, password: "otherpassword")
    sign_in user
    confirm_access!("wrongpassword")

    assert_api_response :post, 400, body: {}
  end

  test "POST /otp/start returns 401 when not signed in" do
    assert_api_response :post, 401, body: {}
  end

  test "POST /otp/start with OAuth bearer + access confirmation" do
    user = create(:user, password: "testtest")
    headers = oauth_headers_for(user, scopes: ["public"], with_access_confirmation: true)

    assert_api_response :post, 200, headers: headers, body: {}
  end

  test "POST /otp/start returns 400 for OAuth bearer without X-Access-Confirmation" do
    user = create(:user, password: "testtest")

    assert_api_response :post, 400, headers: oauth_headers_for(user, scopes: ["public"]), body: {}
  end
end
