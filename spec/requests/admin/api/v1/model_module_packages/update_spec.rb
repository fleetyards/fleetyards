# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_module_packages", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_module_packages]) }
  let(:model_module_package) { create(:model_module_package) }
  let(:id) { model_module_package.id }
  let(:request_body) do
    {
      name: "Updated Package"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-module-packages/{id}" do
    parameter name: "id", in: :path, description: "Model Module Package id", schema: {type: :string, format: :uuid}

    put("Update Model Module Package") do
      operationId "updateModelModulePackage"
      tags "ModelModulePackages"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelModulePackageInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackage"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Updated Package")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
