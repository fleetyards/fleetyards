# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/users", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user, email: "test@fleetyards.dev") }
  let(:request_body) do
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

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/CheckInput"} } }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["taken"]).to eq(true)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"

        let(:request_body) do
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
