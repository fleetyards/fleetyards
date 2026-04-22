# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/password", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user) }
  let(:request_body) do
    {
      email: user.email
    }
  end

  path "/password/request" do
    post("Request Password reset") do
      operationId "requestPasswordReset"
      tags "Password"
      consumes "application/json"
      produces "application/json"

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/PasswordRequestInput"} } }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

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
