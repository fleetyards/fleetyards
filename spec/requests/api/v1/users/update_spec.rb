# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :users

  let(:user) { users :data }
  let(:input) do
    {
      discord: "DiscordServer"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/users/me" do
    put("Update My Data") do
      operationId "updateProfile"
      tags "Users"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/UserUpdateInput"}, required: true

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/User"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["discord"]).to eq("DiscordServer")
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
