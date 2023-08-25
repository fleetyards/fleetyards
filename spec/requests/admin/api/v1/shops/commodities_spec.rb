# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/shops/commodities", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:shop) { shops :new_deal }
  let(:user) { nil }

  before do
    ShopCommodity.reindex

    sign_in user if user.present?
  end

  path "/shops/{shopId}/commodities" do
    parameter name: "shopId", in: :path, schema: {type: :string, format: :uuid}, required: true

    get("Shop Commodities list") do
      operationId "shopCommodities"
      description "Get a List of Shop Commodities"
      produces "application/json"
      tags "Shops"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ShopCommodity.default_per_page}, required: false
      parameter name: "order", in: :query, schema: {"$ref": "#/components/schemas/ShopCommodityOrder"}, required: false
      parameter name: "filters", in: :query,
        schema: {type: :object, "$ref": "#/components/schemas/ShopCommodityQuery"},
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ShopCommodities"

        let(:shopId) { shop.id }
        let(:user) { admin_users :jeanluc }

        after do |example|
          if response&.body.present?
            example.metadata[:response][:content] = {
              "application/json": {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to be > 0
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ShopCommodities"

        let(:shopId) { shop.id }
        let(:user) { admin_users :jeanluc }
        let(:filters) do
          {
            "name" => ["600i"]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ShopCommodities"

        let(:shopId) { shop.id }
        let(:user) { admin_users :jeanluc }
        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
          expect(data.dig("meta", "pagination", "totalPages")).to eq(2)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:shopId) { "invalid-shop-id" }
        let(:user) { admin_users :jeanluc }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:shopId) { shop.id }

        run_test!
      end
    end
  end
end
