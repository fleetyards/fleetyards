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

  path "/fleets/{fleetSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Vehicles List") do
      operationId "fleetVehicles"
      tags "Fleets"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "grouped", in: :query, type: :boolean, required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetVehicles"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(3)
        end

        context "with filter" do
          let(:q) do
            {
              "modelNameCont" => fleet.models.first.name
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            items = data["items"]

            expect(items.count).to eq(1)
            expect(items.first.dig("model", "name")).to eq(fleet.models.first.name)
          end
        end

        context "with perPage" do
          let(:perPage) { 1 }

          run_test! do |response|
            data = JSON.parse(response.body)
            items = data["items"]

            expect(items.count).to eq(1)
          end
        end

        context "with grouped flag" do
          let(:grouped) { true }

          run_test! do |response|
            data = JSON.parse(response.body)
            items = data["items"]

            expect(items.count).to eq(3)
          end
        end

        context "with member" do
          let(:user) { member }

          run_test! do |response|
            data = JSON.parse(response.body)
            items = data["items"]

            expect(items.count).to be > 0
            expect(items.count).to eq(3)
          end
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
