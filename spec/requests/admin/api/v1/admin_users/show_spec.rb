# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/admin_users", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, super_admin: true) }
  let(:admin_user) { create(:admin_user) }
  let(:id) { admin_user.id }

  before do
    sign_in(user) if user.present?
  end

  path "/admin_users/{id}" do
    parameter name: "id", in: :path, description: "Admin User id", schema: {type: :string, format: :uuid}

    get("Admin User Detail") do
      operationId "adminUser"
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

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

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
