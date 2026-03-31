# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/otp", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:password) { "testtest" }
  let(:author) { create :user, password: password, otp_secret: User.generate_otp_secret, otp_required_for_login: false }
  let(:user) { author }
  let(:input) do
    {
      otpCode: author.current_otp
    }
  end

  let(:Authorization) { nil }
  let(:"X-Access-Confirmation") { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    if user.present?
      sign_in(user)

      post confirm_access_api_v1_sessions_path, params: {password: password}, as: :json
    end
  end

  path "/otp/enable" do
    post("Enable OTP Setup") do
      operationId "enableOtpSetup"
      tags "OTP"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/SetupOtpInput"}, required: true
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

        run_test!
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }
        let(:"X-Access-Confirmation") do
          verifier = ActiveSupport::MessageVerifier.new(Rails.application.credentials.confirm_access_secret!, purpose: :access_confirmation)
          verifier.generate(author.id, expires_in: 15.minutes)
        end

        run_test!
      end

      response(400, "requires access confirmation with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { nil }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { create :user, password: password, otp_required_for_login: true }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { create :user, password: "otherpassword" }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:input) { {otpCode: "000000"} }

        run_test!
      end
    end
  end
end
