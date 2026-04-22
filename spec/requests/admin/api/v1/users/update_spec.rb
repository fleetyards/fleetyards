# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/users", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:admin) { create(:admin_user, resource_access: [:users]) }
  let(:user) { create(:user) }
  let(:id) { user.id }
  let(:input) do
    {
      username: "updated_username"
    }
  end

  before do
    sign_in(admin) if admin.present?
  end

  path "/users/{id}" do
    parameter name: "id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    put("Update User") do
      operationId "updateUser"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/UserInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("updated_username")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:admin) { create(:admin_user, resource_access: []) }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:admin) { nil }

        run_test!
      end
    end
  end
end
