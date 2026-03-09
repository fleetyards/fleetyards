# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/features", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:features]) }
  let(:id) { "TestFeature" }

  before do
    sign_in user if user.present?
    Flipper.enable("TestFeature")
  end

  path "/features/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    get("Feature Detail") do
      operationId "adminFeature"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Feature"
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:id) { "NonExistentFeature" }
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
