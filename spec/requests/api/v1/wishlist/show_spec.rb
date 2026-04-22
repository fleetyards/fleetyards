# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/wishlist", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user, vehicle_count: 3) }
  let(:user) { author }
  let(:wanted_vehicles) { create_list(:vehicle, 2, user: author, wanted: true) }

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

    wanted_vehicles
  end

  path "/wishlist" do
    get("Your Wishlist") do
      operationId "wishlist"
      tags "Wishlist"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Vehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Hangar"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
        end
      end

      include_examples "oauth_auth"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Hangar"

        let(:q) do
          {
            "modelNameOrModelDescriptionCont" => wanted_vehicles.first.model.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first.dig("model", "name")).to eq(wanted_vehicles.first.model.name)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Hangar"

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
        end
      end
    end
  end
end
