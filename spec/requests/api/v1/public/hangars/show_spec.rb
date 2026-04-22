# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/public/hangars", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user, :public_hangar) }
  let(:username) { user.username }
  let(:model_with_images) { create(:model, :with_store_image, :with_description) }
  let(:vehicles) { [create(:vehicle, :public, user: user), create(:vehicle, :public, :with_name, user: user, model: model_with_images)] }

  before do
    vehicles
  end

  path "/public/hangars/{username}" do
    parameter name: "username", in: :path, type: :string, required: true

    get("Public Hangar") do
      operationId "publicHangar"
      tags "PublicHangar"
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

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarPublic"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarPublic"

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
        schema "$ref": "#/components/schemas/HangarPublic"

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user, :private_hangar) }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { "not-a-user" }

        run_test!
      end
    end
  end
end
