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

  path "/fleets/{fleetSlug}/stats/vehicles" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Vehicles Stats") do
      operationId "fleetVehiclesStats"
      tags "FleetStats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetVehiclesStats"

        run_test!
      end

      response(404, "successful") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user) }

        run_test!
      end

      response(401, "successful") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
