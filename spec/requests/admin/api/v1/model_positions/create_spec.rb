# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_positions", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_positions]) }
  let(:model) { create(:model) }
  let(:request_body) do
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

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelPositionInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelPosition"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { {modelId: model.id} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
