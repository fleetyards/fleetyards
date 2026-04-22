# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/users", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:admin) { create(:admin_user, resource_access: [:users]) }
  let(:user) { create(:user) }
  let(:id) { user.id }

  before do
    sign_in(admin) if admin.present?
  end

  path "/users/{id}" do
    parameter name: "id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    delete("Destroy User") do
      operationId "destroyUser"
      tags "Users"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"

        run_test!
      end

      response(200, "successful when sole fleet admin") do
        schema "$ref": "#/components/schemas/User"

        before do
          create(:fleet, admins: [user])
        end

        run_test!
      end

      response(400, "blocked by permanent fleet role") do
        schema "$ref": "#/components/schemas/ValidationError"

        before do
          other_user = create(:user)
          create(:fleet, admins: [user], members: [other_user])
        end

        run_test!
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
