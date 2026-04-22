# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/vehicles", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author) }
  let(:request_body) do
    {
      ids: vehicles.pluck(:id),
      wanted: true
    }
  end

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
  end

  path "/vehicles/bulk" do
    put("Update multiple vehicles") do
      operationId "updateBulkVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/VehicleUpdateBulkInput"} } }

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful") do
        run_test!
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
