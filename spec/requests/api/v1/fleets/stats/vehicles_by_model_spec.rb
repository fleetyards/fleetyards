# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{slug}/stats/vehicles-by-model" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Stats - Vehicles by Model") do
      operationId "fleetVehiclesByModel"
      tags "FleetStats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/BarChartStats"}

        let(:slug) { fleet.slug }
        let(:user) { users :data }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { fleet.slug }

        run_test!
      end
    end
  end
end
