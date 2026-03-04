# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/admin_users", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, super_admin: true) }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/AdminUserInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUser"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("newadmin")
        end
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, super_admin: false) }

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
