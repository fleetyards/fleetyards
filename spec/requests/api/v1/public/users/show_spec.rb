# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/public/users", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user, :with_avatar, :with_rsi_handle, :with_social_links, :public_hangar) }
  let(:user_without_public_hangar) { create(:user, :private_hangar) }

  path "/public/users/{username}" do
    parameter name: "username", in: :path, schema: {type: :string}, required: true

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

      response(404, "not found", hidden: true) do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { "not-a-user" }

        run_test!
      end
    end
  end
end
