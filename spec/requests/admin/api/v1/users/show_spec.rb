# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/users", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:admin) { create(:admin_user, resource_access: [:users]) }
  let(:user) { create(:user) }
  let(:id) { user.id }

  before do
    sign_in(admin) if admin.present?
  end

  path "/users/{id}" do
    parameter name: "id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    get("User Detail") do
      operationId "user"
      tags "Users"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"

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
