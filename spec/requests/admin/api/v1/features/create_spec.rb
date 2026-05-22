# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/features", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:features]) }

  before do
    sign_in user if user.present?
  end

  path "/features" do
    post("Create Feature") do
      operationId "createAdminFeature"
      tags "Features"
      consumes "application/json"
      produces "application/json"
      request_body schema: {"$ref": "#/components/schemas/FeatureInput"}

      response(201, "created") do
        schema "$ref": "#/components/schemas/Feature"
        let(:request_body) { {name: "new-feature"} }
        run_test!
      end

      response(422, "invalid") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:request_body) { {name: ""} }
        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:user) { create(:admin_user, resource_access: []) }
        let(:request_body) { {name: "new-feature"} }
        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:user) { nil }
        let(:request_body) { {name: "new-feature"} }
        run_test!
      end
    end
  end
end
