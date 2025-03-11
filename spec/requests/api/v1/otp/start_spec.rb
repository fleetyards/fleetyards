# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/otp", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:password) { "testtest" }
  let(:user) { create :user, password: password }

  before do
    sign_in(user) if user.present?

    post confirm_access_api_v1_sessions_path, params: {password: password}
  end

  path "/otp/start" do
    post("Start OTP Setup") do
      operationId "startOtpSetup"
      tags "OTP"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

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
