# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user, vehicle_count: 2) }
  let(:fleet) { create(:fleet, members: [member]) }
  let(:user) { member }
  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/stats/vehicles-by-model" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Stats - Vehicles by Model") do
      operationId "fleetVehiclesByModel"
      tags "FleetStats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/BarChartStats"}

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
