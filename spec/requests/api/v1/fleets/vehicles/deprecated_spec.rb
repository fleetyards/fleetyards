# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  let(:user) { nil }

  let(:slug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{slug}/public-vehicles" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Public Vehicles -> use GET /fleets/{slug}/public/vehicles") do
      deprecated true
      operationId "DEPRECATEDfleetPublicVehicles"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        run_test!
      end
    end
  end

  path "/fleets/{slug}/fleetchart" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Fleetchart -> use GET /fleets/{slug}/vehicles") do
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

  path "/fleets/{slug}/public-fleetchart" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Public Fleetchart -> use GET /fleets/{slug}/public/vehicles") do
      deprecated true
      operationId "DEPRECATEDpublicFleetchart"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        run_test!
      end
    end
  end

  path "/fleets/{slug}/quick-stats" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Vehicle QuickStats -> use GET /fleets/{slug}/stats/vehicles") do
      deprecated true
      operationId "DEPRECATEDpublicFleetchart"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        let(:user) { users :data }

        run_test!
      end
    end
  end

  path "/fleets/{slug}/model-counts" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Stats Model Counts -> use GET /fleets/{slug}/stats/model-counts") do
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

        let(:slug) { fleet.slug }
        let(:user) { users :data }

        run_test!
      end
    end
  end

  path "/fleets/{slug}/public-model-counts" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Public Fleet Stats Model Counts -> use GET /public/fleets/{slug}/stats/model-counts") do
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

        let(:slug) { fleet.slug }
        let(:user) { users :data }

        run_test!
      end
    end
  end
  path "/fleets/{slug}/embed" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Vehicles Embed for the Fleetyards Widget -> use GET /public/fleets/{slug}/vehicles/embed") do
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

        let(:slug) { fleet.slug }

        run_test!
      end
    end
  end
end
