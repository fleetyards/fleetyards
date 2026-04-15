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

      include_examples "admin_auth", forbidden_user: -> { create(:admin_user, super_admin: false) }
    end
  end
end
