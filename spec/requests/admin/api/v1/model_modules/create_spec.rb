# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_modules", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_modules]) }
  let(:model) { create(:model) }
  let(:input) do
    {
      name: "Cargo Module",
      modelId: model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-modules" do
    post("Create new Model Module") do
      operationId "createModelModule"
      tags "ModelModules"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelModuleInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelModule"

        run_test! do
          created_module = ModelModule.last

          expect(created_module.module_hardpoints.count).to eq(1)
          expect(created_module.module_hardpoints.first.model_id).to eq(model.id)
        end
      end

      include_examples "admin_auth"
    end
  end
end
