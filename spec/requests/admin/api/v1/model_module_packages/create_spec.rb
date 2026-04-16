# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_module_packages", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_module_packages]) }
  let(:model) { create(:model) }
  let(:input) do
    {
      name: "Starter Package",
      modelId: model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-module-packages" do
    post("Create Model Module Package") do
      operationId "createModelModulePackage"
      tags "ModelModulePackages"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelModulePackageInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackage"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Starter Package")
        end
      end

      include_examples "admin_auth"
    end
  end
end
