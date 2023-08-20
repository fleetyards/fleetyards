# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/search", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  before do
    Shop.reindex
    ShopCommodity.reindex
    Commodity.reindex
    Model.reindex
    Equipment.reindex
    Component.reindex
    Station.reindex
    CelestialObject.reindex
    Starsystem.reindex
  end

  path "/search" do
    get("list searches") do
      tags "Search"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/SearchQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/SearchResult"}

        let(:q) do
          {
            search: "Galaxy"
          }
        end

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first.dig("item", "name")).to eq("Galaxy")
        end
      end
    end
  end
end
