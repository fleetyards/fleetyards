# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/features", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:features]) }
  let(:id) { "TestFeature" }

  before do
    sign_in user if user.present?
    Flipper.add("TestFeature")
  end

  path "/features/{id}/enable-group" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Enable Feature for Group") do
      operationId "enableAdminFeatureGroup"
      tags "Features"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FeatureGroupInput"}

      let(:request_body) { {group: "testers"} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Feature"
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:id) { "NonExistentFeature" }
        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
