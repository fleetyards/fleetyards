# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/sessions", type: :openapi, openapi_schema_name: :"v1/schema" do
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
