# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/public/fleets/stats", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:member) { create(:user, vehicle_count: 3) }
  let(:fleet) { create(:fleet, public_fleet_stats: true, members: [member]) }
  let(:fleetSlug) { fleet.slug }

  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Testing.fake!
  end

  path "/public/fleets/{fleetSlug}/stats/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: { type: :string }, description: "Fleet slug"

    get("Public Fleet Vehicles Stats") do
      operationId "publicFleetVehiclesStats"
      tags "FleetStats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetVehiclesStats"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleet) { create(:fleet, public_fleet_stats: false) }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end
    end
  end
end
