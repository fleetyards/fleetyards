# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/sessions", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:password) { "enterprise" }
  let(:user) { create(:user, password:) }
  let(:input) do
    {
      login: user.username,
      password: password
    }
  end

  path "/sessions" do
    post("create session") do
      operationId "createSession"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/SessionInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:input) { nil }

        run_test!
      end
    end
  end
end
