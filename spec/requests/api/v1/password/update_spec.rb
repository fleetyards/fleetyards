# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/password", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user, password: "enterprise") }
  let(:request_body) do
    {
      password: "73b8680678a4a2725bba6a88b84b550828b27ca606",
      passwordConfirmation: "73b8680678a4a2725bba6a88b84b550828b27ca606"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/password" do
    put("Update password") do
      operationId "updatePassword"
      tags "Password"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/PasswordInput"}

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { nil }

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
