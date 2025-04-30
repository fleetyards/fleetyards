# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user, wanted_vehicle_count: 2) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author) }

  before do
    sign_in(user) if user.present?

    vehicles
  end

  path "/hangar/stats/models-by-classification" do
    get("Hangar Stats - Models by Classification") do
      operationId "hangarModelsByClassification"
      tags "HangarStats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/PieChartStats"}

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
