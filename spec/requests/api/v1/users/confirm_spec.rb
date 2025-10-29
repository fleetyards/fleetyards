# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:token) { SecureRandom.hex(16) }
  let(:user) { create :user, confirmed_at: nil, confirmation_token: token }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ConfirmAccountInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) do
          {
            token: "invalid"
          }
        end

        run_test!
      end
    end
  end
end
