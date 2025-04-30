# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, email: "test@fleetyards.dev") }
  let(:input) do
    {
      value: "test@fleetyards.dev"
    }
  end

  before do
    user
  end

  path "/users/check-email" do
    post("Check E-Mail Availability") do
      operationId "checkEmail"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/CheckInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["taken"]).to eq(true)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"

        let(:input) do
          {
            value: "test1@fleetyards.dev"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["taken"]).to eq(false)
        end
      end
    end
  end
end
