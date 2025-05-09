# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/shops", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:shop) { shops :new_deal }

  before do
    ShopCommodity.reindex
  end

  path "/stations/{stationSlug}/shops/{slug}/commodities" do
    parameter name: "slug", in: :path, type: :string, required: true
    parameter name: "stationSlug", in: :path, type: :string, required: true

    get("Shop Commodity list") do
      operationId "shopCommodities"
      tags "Shops"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: ShopCommodity.default_per_page}, required: false
      parameter name: "search", in: :query, type: :string, required: false
      parameter name: "query", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ShopCommodityQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "order", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ShopCommodityOrderQuery"
        },
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}

        let(:stationSlug) { shop.station.slug }
        let(:slug) { shop.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}

        let(:stationSlug) { shop.station.slug }
        let(:slug) { shop.slug }
        let(:query) do
          {
            "name" => ["600i Explorer"]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first["name"]).to eq("600i Explorer")
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ShopCommodity"}

        let(:stationSlug) { shop.station.slug }
        let(:slug) { shop.slug }
        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:stationSlug) { shop.station.slug }
        let(:slug) { "unknown" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:stationSlug) { "unknown" }
        let(:slug) { shop.slug }

        run_test!
      end
    end
  end
end
