# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/otp", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:password) { "testtest" }
  let(:user) { create :user, password: password, otp_secret: User.generate_otp_secret, otp_required_for_login: true }
  let(:input) do
    {
      otpCode: user&.current_otp
    }
  end

  before do
    sign_in(user) if user.present?

    post confirm_access_api_v1_sessions_path, params: {password: password}
  end

  path "/otp/disable" do
    post("Disable OTP Setup") do
      operationId "disableOtpSetup"
      tags "OTP"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/SetupOtpInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { nil }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { create :user, password: password, otp_required_for_login: false }

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
