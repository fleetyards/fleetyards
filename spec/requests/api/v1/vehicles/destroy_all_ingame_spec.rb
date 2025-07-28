# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author, bought_via: :pledge_store) }
  let(:ingame_vehicles) { create_list(:vehicle, 3, user: author, bought_via: :ingame) }

  before do
    sign_in(user) if user.present?

    vehicles
    ingame_vehicles
  end

  path "/vehicles/destroy-all-ingame" do
    delete("Delete all ingame bought Vehicles") do
      operationId "destroyAllIngameVehicles"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      response(204, "successful") do
        run_test! do
          expect(user.vehicle_ids.sort).to eq(vehicles.pluck(:id).sort)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
