# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_modules", type: :request, swagger_doc: "admin/v1/schema.yaml" do
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

      parameter name: :id, in: :path, type: :string, format: :uuid, required: true
      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid}
        },
        required: [:modelId]
      }, required: true

      let(:input) { {modelId: model.id} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModule"

        run_test! do
          expect(ModuleHardpoint.where(model_id: model.id, model_module_id: model_module.id).count).to eq(1)
        end
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

  path "/model-modules/{id}/unlink" do
    put("Unlink Model Module from Model") do
      operationId "unlinkModelModule"
      tags "ModelModules"

      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, type: :string, format: :uuid, required: true
      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid}
        },
        required: [:modelId]
      }, required: true

      let(:input) { {modelId: model.id} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModule"

        before do
          create(:module_hardpoint, model: model, model_module: model_module)
        end

        run_test! do
          expect(ModuleHardpoint.where(model_id: model.id, model_module_id: model_module.id).count).to eq(0)
        end
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
