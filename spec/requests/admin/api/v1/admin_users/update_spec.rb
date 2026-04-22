# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/admin_users", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, super_admin: true) }
  let(:admin_user) { create(:admin_user) }
  let(:id) { admin_user.id }
  let(:input) do
    {
      username: "updated_admin"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/admin_users/{id}" do
    parameter name: "id", in: :path, description: "Admin User id", schema: {type: :string, format: :uuid}

    put("Update Admin User") do
      operationId "updateAdminUser"
      tags "AdminUsers"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/AdminUserInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUser"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("updated_admin")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth", forbidden_user: -> { create(:admin_user, super_admin: false) }
    end
  end
end
