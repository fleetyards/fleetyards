# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/fleets/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  path "/public/fleets/{fleetSlug}/stats/members" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Public Fleet Members Stats") do
      operationId "publicFleetMembersStats"
      tags "FleetStats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetMembersStatsPublic"

        let(:fleetSlug) { fleet.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end


      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleet) { fleets :klingon_empire }
        let(:fleetSlug) { fleet.slug }

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
