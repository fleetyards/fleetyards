# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/vehicles", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author, bought_via: :pledge_store) }
  let(:ingame_vehicles) { create_list(:vehicle, 3, user: author, bought_via: :ingame) }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

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

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect(user.vehicle_ids.sort).to eq(vehicles.pluck(:id).sort)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
