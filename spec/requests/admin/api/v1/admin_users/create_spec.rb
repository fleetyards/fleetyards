# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/admin_users", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, super_admin: true) }
  let(:request_body) do
    {
      username: "newadmin",
      email: "newadmin@example.com",
      password: "password123",
      passwordConfirmation: "password123"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/admin_users" do
    post("Create Admin User") do
      operationId "createAdminUser"
      tags "AdminUsers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/AdminUserInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUser"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("newadmin")
        end
      end

      include_examples "admin_auth", forbidden_user: -> { create(:admin_user, super_admin: false) }
    end
  end
end
