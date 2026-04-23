# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/password", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user) }
  let(:token) { user.send_reset_password_instructions }
  let(:request_body) do
    {
      password: "73b8680678a4a2725bba6a88b84b550828b27ca606",
      passwordConfirmation: "73b8680678a4a2725bba6a88b84b550828b27ca606"
    }
  end

  path "/password/{token}" do
    parameter name: :token, in: :path, schema: {type: :string}, required: true

    put("Update Password with Token") do
      operationId "updatePasswordWithToken"
      tags "Password"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/PasswordInput"}

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

        let(:request_body) { nil }

        run_test!
      end
    end
  end
end
