# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/otp", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:password) { "testtest" }
  let(:author) { create :user, password: password }
  let(:user) { author }

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

  path "/otp/start" do
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

        run_test!
      end
    end
  end
end
