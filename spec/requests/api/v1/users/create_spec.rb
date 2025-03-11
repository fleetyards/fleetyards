# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :users

  let(:user) { nil }
  let(:input) do
    {
      username: "TestUser",
      email: "test@fleetyards.net",
      password: "password",
      passwordConfirmation: "password",
      saleNotify: true,
      fleetInviteToken: "ee86f1f1dbb8799dcb6f5cb9efd73f"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/users/signup" do
    post("Create new User") do
      operationId "signup"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/UserCreateInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/User"

        run_test!
      end

      response(422, "unprocessable entity") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users(:data) }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { nil }

        run_test!
      end
    end
  end
end
