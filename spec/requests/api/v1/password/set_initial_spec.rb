# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/password", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, :oauth_only) }
  let(:input) do
    {
      password: "73b8680678a4a2725bba6a88b84b550828b27ca606",
      passwordConfirmation: "73b8680678a4a2725bba6a88b84b550828b27ca606"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/password/set-initial" do
    post("Set initial password for OAuth-only users") do
      operationId "setInitialPassword"
      tags "Password"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/SetInitialPasswordInput"}, required: true

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test! do |response|
          expect(user.reload.password_set_manually).to be true
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) do
          {
            password: "short",
            passwordConfirmation: "mismatch"
          }
        end

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end

      response(403, "forbidden - user already has password") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user, password: "enterprise", password_set_manually: true) }

        run_test!
      end
    end
  end
end
