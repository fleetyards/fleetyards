# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/admin_users", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, super_admin: true) }
  let(:admin_user) { create(:admin_user) }
  let(:id) { admin_user.id }

  before do
    sign_in(user) if user.present?
  end

  path "/admin_users/{id}" do
    parameter name: "id", in: :path, description: "Admin User id", schema: {type: :string, format: :uuid}

    delete("Destroy Admin User") do
      operationId "destroyAdminUser"
      tags "AdminUsers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUser"

        run_test!
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
