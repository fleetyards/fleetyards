# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user, :with_rsi_handle, wanted_vehicle_count: 2) }
  let(:user) { author }
  let(:model_with_images) { create(:model, :with_store_image, :with_description) }
  let(:vehicles) { create_list(:vehicle, 2, user: author) + [create(:vehicle, :with_name, :flagship, user: author, model: model_with_images)] }

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

  path "/hangar" do
    get("Your personal Hangar") do
      operationId "hangar"
      tags "Hangar"
      produces "application/json"

      security [
        { SessionCookie: [] },
        { Oauth2: ["hangar", "hangar:read"] },
        { OpenId: ["hangar", "hangar:read"] }
      ]

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Vehicle.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: {
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Hangar"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
        end
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }

        run_test!
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Hangar"

        let(:q) do
          {
            "modelNameOrModelDescriptionCont" => vehicles.first.model.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first.dig("model", "name")).to eq(vehicles.first.model.name)
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

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:q) do
          {
            "foo" => "bar"
          }
        end

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
