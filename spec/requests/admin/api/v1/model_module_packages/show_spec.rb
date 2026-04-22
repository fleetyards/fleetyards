# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_module_packages", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_module_packages]) }
  let(:model_module_package) { create(:model_module_package) }
  let(:id) { model_module_package.id }

  before do
    sign_in(user) if user.present?
  end

  path "/model-module-packages/{id}" do
    parameter name: "id", in: :path, description: "Model Module Package id", schema: {type: :string, format: :uuid}

    get("Model Module Package Detail") do
      operationId "modelModulePackage"
      tags "ModelModulePackages"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackage"

        run_test!
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
