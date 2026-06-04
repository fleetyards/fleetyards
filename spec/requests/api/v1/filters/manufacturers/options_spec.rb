# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/filters/manufacturers", type: :openapi, openapi_schema_name: :"v1/schema" do
  let!(:manufacturers) do
    create_list(:manufacturer, 6, :with_logo, :with_models)
  end

  path "/filters/manufacturers/options" do
    get("Manufacturer Options") do
      operationId "manufacturerOptions"
      tags "ManufacturersFilters"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Manufacturer.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ManufacturerQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ManufacturerOptions"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(6)
          expect(items.first.keys).to match_array(%w[id name slug logo])
        end
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/ManufacturerOptions"

        let(:q) do
          {
            "nameCont" => manufacturers.first.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first["name"]).to eq(manufacturers.first.name)
        end
      end
    end
  end
end
