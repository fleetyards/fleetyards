# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user, vehicle_count: 2) }
  let(:member) { create(:user, vehicle_count: 1) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:fleetSlug) { fleet.slug }

  before do
    Sidekiq::Testing.inline!

    sign_in(user) if user.present?
  end

  after do
    Sidekiq::Testing.fake!
  end

  path "/fleets/{fleetSlug}/vehicles/export" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Vehicles List") do
      operationId "fleetVehiclesExport"
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
        schema type: :array, items: {"$ref": "#/components/schemas/FleetVehicleExport"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(3)
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FleetVehicleExport"}

        let(:q) do
          {
            "modelNameCont" => fleet.models.first.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first["name"]).to eq(fleet.models.first.name)
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FleetVehicleExport"}

        let(:user) { member }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(3)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

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
