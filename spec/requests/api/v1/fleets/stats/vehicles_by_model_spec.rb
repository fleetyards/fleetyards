# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/stats", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:member) { create(:user, vehicle_count: 2) }
  let(:fleet) { create(:fleet, members: [member]) }
  let(:user) { member }
  let(:fleetSlug) { fleet.slug }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: member.id,
      scopes: ["fleet", "fleet:read"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: member.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/stats/vehicles-by-model" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Stats - Vehicles by Model") do
      operationId "fleetVehiclesByModel"
      tags "FleetStats"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/BarChartStats"}

        run_test!
      end

      include_examples "oauth_auth"
    end
  end
end
