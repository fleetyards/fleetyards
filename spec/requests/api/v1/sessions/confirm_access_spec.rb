# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/sessions", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :users

  let(:user) { users :data }

  before do
    sign_in(user) if user.present?
  end

  path "/sessions/confirm-access" do
    post("confirm_access session") do
      operationId "confirmAccess"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ConfirmAccessInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        let(:input) do
          {
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

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:input) do
          {
            password: "enterprise"
          }
        end

        run_test!
      end
    end
  end
end
