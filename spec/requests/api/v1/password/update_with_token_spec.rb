# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/password", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:token) { user.send_reset_password_instructions }
  let(:input) do
    {
      currentPassword: "enterprise",
      password: "73b8680678a4a2725bba6a88b84b550828b27ca606",
      passwordConfirmation: "73b8680678a4a2725bba6a88b84b550828b27ca606"
    }
  end

  path "/password/{token}" do
    parameter name: :token, in: :path, type: :string, required: true

    put("Update Password with Token") do
      operationId "updatePasswordWithToken"
      tags "Password"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/PasswordInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:token) { "unknown" }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { nil }

        run_test!
      end
    end
  end
end
