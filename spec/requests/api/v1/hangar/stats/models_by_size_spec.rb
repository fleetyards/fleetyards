# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/hangar/stats", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user, wanted_vehicle_count: 2) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author) }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:read"]
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
  end

  path "/hangar/stats/models-by-size" do
    get("Hangar Stats - Models by Size") do
      operationId "hangarModelsBySize"
      tags "HangarStats"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/PieChartStats"}

        run_test!
      end

      include_examples "oauth_auth"
    end
  end
end
