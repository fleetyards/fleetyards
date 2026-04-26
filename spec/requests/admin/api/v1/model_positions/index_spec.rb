# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_positions", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_positions]) }
  let(:model_positions) { create_list(:model_position, 3) }

  before do
    sign_in user if user.present?

    model_positions
  end

  path "/model-positions" do
    get("Model Positions list") do
      operationId "listModelPositions"
      tags "ModelPositions"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelPosition.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelPositionQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPositions"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      include_examples "admin_auth"
    end
  end
end
