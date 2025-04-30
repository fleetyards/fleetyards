# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/password", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/PasswordRequestInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

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
