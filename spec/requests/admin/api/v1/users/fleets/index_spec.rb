# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/users/:user_id/fleets", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:admin) { create(:admin_user, resource_access: [:users]) }
  let(:user) { create(:user) }
  let(:user_id) { user.id }

  before do
    sign_in(admin) if admin.present?
  end

  path "/users/{user_id}/fleets" do
    parameter name: "user_id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    get("User Fleets list") do
      operationId "userFleets"
      tags "Users"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUserFleets"

        before do
          create(:fleet, admins: [user])
          create(:fleet, members: [user])
        end

        run_test!
      end

      response(200, "successful with no fleets") do
        schema "$ref": "#/components/schemas/AdminUserFleets"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user_id) { SecureRandom.uuid }

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
