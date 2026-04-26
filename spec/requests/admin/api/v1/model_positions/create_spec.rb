# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_positions", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_positions]) }
  let(:model) { create(:model) }
  let(:input) do
    {
      modelId: model.id,
      name: "Passenger 1",
      positionType: "passenger",
      source: "curated",
      position: 5
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-positions" do
    post("Create new Model Position") do
      operationId "createModelPosition"
      tags "ModelPositions"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelPositionInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelPosition"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { {modelId: model.id} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
