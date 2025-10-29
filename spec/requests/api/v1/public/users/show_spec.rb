# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/users", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:user_without_public_hangar) { create(:user, public_hangar: false) }

  path "/public/users/{username}" do
    parameter name: "username", in: :path, type: :string, required: true

    get("Public User") do
      operationId "publicUser"
      tags "PublicUser"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/UserPublic"

        let(:username) { user.username }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq(user.username)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { user_without_public_hangar.username }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { "not-a-user" }

        run_test!
      end
    end
  end
end
