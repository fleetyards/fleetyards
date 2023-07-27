# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/shop_commodities", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:shop_commodity) { shop_commodities :commodity_four }
  let(:user) { nil }

  before do
    sign_in user if user.present?
  end

  path "/shop-commodities/{id}" do
    parameter name: "id", in: :path, description: "Shop Commodity ID", schema: {type: :string, format: :uuid}, required: true

    delete("Shop Commodity Destroy") do
      operationId "destroyShopCommodity"
      tags "ShopCommodities"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ShopCommodityMinimal"

        let(:id) { shop_commodity.id }
        let(:user) { admin_users :jeanluc }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }
        let(:user) { admin_users :jeanluc }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { shop_commodity.id }

        run_test!
      end
    end
  end
end
