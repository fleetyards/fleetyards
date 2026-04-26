# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_positions", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_positions]) }
  let(:model) { create(:model) }
  let(:model_id) { model.id }

  before do
    sign_in(user) if user.present?

    create(:model_position, model: model)
  end

  path "/model-positions/regenerate" do
    put("Regenerate Model Positions") do
      operationId "regenerateModelPositions"
      tags "ModelPositions"

      consumes "application/json"
      produces "application/json"

      parameter name: :model_id, in: :query, schema: {type: :string, format: :uuid}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPositions"

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
