# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, username: "data") }
  let(:input) do
    {
      value: "data"
    }
  end

  before do
    user
  end

  path "/users/check-username" do
    post("Check Username Availability") do
      operationId "checkUsername"
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
            value: "Picard"
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
