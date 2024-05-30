# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/sessions", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :admin_users

  let(:user) { admin_users :jeanluc }

  path "/sessions" do
    post("create session") do
      operationId "createSession"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/SessionInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        let(:input) do
          {
            login: user.username,
            password: "enterprise"
          }
        end

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

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
