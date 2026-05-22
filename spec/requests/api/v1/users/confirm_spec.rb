# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/users", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:token) { SecureRandom.hex(16) }
  let(:user) { create :user, confirmed_at: nil, confirmation_token: token }
  let(:request_body) do
    {
      token: token
    }
  end

  before do
    user
  end

  path "/users/confirm" do
    post("Confirm Account") do
      operationId "confirmAccount"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ConfirmAccountInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) do
          {
            token: "invalid"
          }
        end

        run_test!
      end
    end
  end
end
