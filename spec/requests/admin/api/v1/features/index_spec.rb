# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/features", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:features]) }

  before do
    sign_in user if user.present?
    Flipper.enable("TestFeature")
  end

  path "/features" do
    get("Features list") do
      operationId "adminFeatures"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Feature"}

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first["name"]).to be_present
        end
      end

      include_examples "admin_auth"
    end
  end
end
