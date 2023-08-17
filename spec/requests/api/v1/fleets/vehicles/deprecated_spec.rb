# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  let(:user) { nil }

  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/public-vehicles" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Public Vehicles -> use GET /fleets/{fleetSlug}/public/vehicles") do
      deprecated true
      operationId "DEPRECATEDfleetPublicVehicles"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {
            oneOf: [
              {"$ref": "#/components/schemas/ModelMinimal"},
              {"$ref": "#/components/schemas/VehiclePublicMinimal"}
            ]
          }

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/fleetchart" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Fleetchart -> use GET /fleets/{fleetSlug}/vehicles") do
      deprecated true
      operationId "DEPRECATEDfleetFleetchart"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        let(:user) { users :data }

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/public-fleetchart" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Public Fleetchart -> use GET /fleets/{fleetSlug}/public/vehicles") do
      deprecated true
      operationId "DEPRECATEDpublicFleetFleetchart"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/quick-stats" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Vehicle QuickStats -> use GET /fleets/{fleetSlug}/stats/vehicles") do
      deprecated true
      operationId "DEPRECATEDfleetVehicleQuickStats"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetVehiclesStats"

        let(:user) { users :data }

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/model-counts" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Stats Model Counts -> use GET /fleets/{fleetSlug}/stats/model-counts") do
      operationId "DEPRECATEDfleetStatsModelCounts"
      deprecated true
      tags "Fleets"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"

        let(:user) { users :data }

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/public-model-counts" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Public Fleet Stats Model Counts -> use GET /public/fleets/{fleetSlug}/stats/model-counts") do
      operationId "DEPRECATEDpublicFleetStatsModelCounts"
      deprecated true
      tags "Fleets"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"

        let(:user) { users :data }

        run_test!
      end
    end
  end
  path "/fleets/{fleetSlug}/embed" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Vehicles Embed for the Fleetyards Widget -> use GET /public/fleets/{fleetSlug}/vehicles/embed") do
      deprecated true
      operationId "DEPRECATEDfleetVehiclesEmbed"
      tags "Fleets"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublicMinimal"}

        run_test!
      end
    end
  end
end
