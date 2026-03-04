# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_paints", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_paints]) }
  let(:model_paint) { create(:model_paint) }
  let(:id) { model_paint.id }

  before do
    sign_in(user) if user.present?
  end

  path "/model-paints/{id}" do
    parameter name: "id", in: :path, description: "Model Paint id", schema: {type: :string, format: :uuid}

    get("Model Paint Detail") do
      operationId "modelPaint"
      tags "ModelPaints"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaint"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
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
