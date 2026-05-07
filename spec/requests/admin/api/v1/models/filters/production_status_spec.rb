# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/models", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:models]) }

  before do
    sign_in user if user.present?
  end

  path "/models/production-states" do
    get("Model Production states") do
      operationId "modelProductionStates"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
