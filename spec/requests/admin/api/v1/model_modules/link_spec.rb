# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_modules", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_modules]) }
  let(:model) { create(:model) }
  let(:model_module) { create(:model_module) }
  let(:id) { model_module.id }

  before do
    sign_in(user) if user.present?
  end

  path "/model-modules/{id}/link" do
    put("Link Model Module to Model") do
      operationId "linkModelModule"
      tags "ModelModules"

      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, required: true, schema: {type: :string, format: :uuid}
      request_body required: true, content: { "application/json" => { schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid}
        },
        required: [:modelId]
      } } }

      let(:request_body) { {modelId: model.id} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModule"

        run_test! do
          expect(ModuleHardpoint.where(model_id: model.id, model_module_id: model_module.id).count).to eq(1)
        end
      end

      include_examples "admin_auth"
    end
  end

  path "/model-modules/{id}/unlink" do
    put("Unlink Model Module from Model") do
      operationId "unlinkModelModule"
      tags "ModelModules"

      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, required: true, schema: {type: :string, format: :uuid}
      request_body required: true, content: { "application/json" => { schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid}
        },
        required: [:modelId]
      } } }

      let(:request_body) { {modelId: model.id} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModule"

        before do
          create(:module_hardpoint, model: model, model_module: model_module)
        end

        run_test! do
          expect(ModuleHardpoint.where(model_id: model.id, model_module_id: model_module.id).count).to eq(0)
        end
      end

      include_examples "admin_auth"
    end
  end
end
