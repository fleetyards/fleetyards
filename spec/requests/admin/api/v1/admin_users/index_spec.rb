# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/admin_users", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, super_admin: true) }

  before do
    sign_in(user) if user.present?
  end

  path "/admin_users" do
    get("Admin Users list") do
      operationId "adminUsers"
      tags "AdminUsers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUsers"

        run_test!
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
