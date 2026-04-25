# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/hangar", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user, :with_rsi_handle, wanted_vehicle_count: 2) }
  let(:user) { author }
  let(:model_alpha) { create(:model, name: "Alpha") }
  let(:model_bravo) { create(:model, name: "Bravo") }
  let(:model_with_images) { create(:model, :with_store_image, :with_description, name: "Charlie") }
  let(:vehicles) { [create(:vehicle, user: author, model: model_alpha), create(:vehicle, user: author, model: model_bravo), create(:vehicle, :with_name, :flagship, user: author, model: model_with_images)] }

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
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Vehicle.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
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

      include_examples "oauth_auth"

      response(200, "successful", hidden: true) do
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

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/Hangar"

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Hangar"

        context "sorted by modelName asc" do
          let(:q) { {"sorts" => "modelName asc"} }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data["items"].map { |m| m.dig("model", "name") }

            expect(names).to eq(%w[Alpha Bravo Charlie])
          end
        end

        context "sorted by modelName desc" do
          let(:q) { {"sorts" => "modelName desc"} }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data["items"].map { |m| m.dig("model", "name") }

            expect(names).to eq(%w[Charlie Bravo Alpha])
          end
        end

        context "sorted by modelName asc via s param" do
          let(:q) { {"s" => "modelName asc"} }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data["items"].map { |m| m.dig("model", "name") }

            expect(names).to eq(%w[Alpha Bravo Charlie])
          end
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
    end
  end
end
