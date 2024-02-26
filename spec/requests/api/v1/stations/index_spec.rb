# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/stations", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/stations" do
    get("Stations list") do
      operationId "stations"
      tags "Stations"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Station.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/StationQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Stations"

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(4)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Stations"

        let(:q) do
          {
            "nameCont" => "Port Olisar"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first["name"]).to eq("Port Olisar")
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Stations"

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Stations"

        let(:q) do
          {
            sorts: ["station_type asc", "name asc"]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.first["name"]).to eq("Covalex Shipping Hub")
        end
      end
    end
  end
end
