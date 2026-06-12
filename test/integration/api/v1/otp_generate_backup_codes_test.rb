# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::OtpGenerateBackupCodesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/otp/generate-backup-codes" do
    post("Generate OTP Backup Codes") do
      operationId "generateOtpBackupCodes"
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
        schema "$ref": "#/components/schemas/OtpBackupCodes"
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

  test "POST /otp/generate-backup-codes returns new backup codes" do
    user = create(:user, password: "testtest", otp_secret: User.generate_otp_secret, otp_required_for_login: true)
    sign_in user
    confirm_access!("testtest")

    assert_api_response :post, 200, body: {}
  end

  test "POST /otp/generate-backup-codes returns 400 when OTP not enabled" do
    user = create(:user, password: "testtest", otp_required_for_login: false)
    sign_in user
    confirm_access!("testtest")

    assert_api_response :post, 400, body: {}
  end

  test "POST /otp/generate-backup-codes returns 401 when not signed in" do
    assert_api_response :post, 401, body: {}
  end

  test "POST /otp/generate-backup-codes with OAuth bearer + access confirmation" do
    user = create(:user, password: "testtest", otp_secret: User.generate_otp_secret, otp_required_for_login: true)
    headers = oauth_headers_for(user, scopes: ["public"], with_access_confirmation: true)

    assert_api_response :post, 200, headers: headers, body: {}
  end

  test "POST /otp/generate-backup-codes returns 400 for OAuth bearer without X-Access-Confirmation" do
    user = create(:user, password: "testtest", otp_secret: User.generate_otp_secret, otp_required_for_login: true)

    assert_api_response :post, 400, headers: oauth_headers_for(user, scopes: ["public"]), body: {}
  end
end
