# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :users

  let(:user) { users :data }
  let(:input) do
    {
      username: "TestUser"
    }
  end

  before do
    if user.present?
      sign_in(user)

      post confirm_access_api_v1_sessions_path, params: {password: "enterprise"}
    end
  end

  path "/users/account" do
    put("Update My Account") do
      operationId "updateAccount"
      tags "Users"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/AccountUpdateInput"}, required: true

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/User"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("TestUser")
        end
      end

      response(400, "bad request") do
        schema "$ref" => "#/components/schemas/ValidationError"

        let(:input) do
          {
            username: ""
          }
        end

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
