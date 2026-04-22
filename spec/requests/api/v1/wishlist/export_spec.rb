# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/wishlist", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user, wanted_vehicle_count: 2, vehicle_count: 3) }
  let(:user) { author }

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
  end

  path "/wishlist/export" do
    get("Export your Wishlist") do
      operationId "exportWishlist"
      tags "Wishlist"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehicleExport"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
      end

      include_examples "oauth_auth"
    end
  end
end
