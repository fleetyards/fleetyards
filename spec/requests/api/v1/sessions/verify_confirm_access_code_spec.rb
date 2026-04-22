# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/sessions", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user, :oauth_only) }
  let(:confirmation_code) { "123456" }
  let(:token) do
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.credentials.confirm_access_secret!, purpose: :access_confirmation)
    verifier.generate({user_id: user.id, code: confirmation_code}, expires_in: 15.minutes)
  end
  let(:input) { {token:, confirmationCode: confirmation_code} }

  before do
    sign_in(user) if user.present?
  end

  path "/sessions/confirm-access-code" do
    post("Verify confirm access code") do
      operationId "verifyConfirmAccessCode"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ConfirmAccessCodeInput"}, required: true

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(400, "bad request - invalid code") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:input) { {token:, confirmationCode: "000000"} }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:token) { "invalid" }
        let(:input) { {token:, confirmationCode: "000000"} }

        run_test!
      end
    end
  end
end
