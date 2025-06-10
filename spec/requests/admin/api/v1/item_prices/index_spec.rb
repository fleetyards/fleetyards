# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/item_prices", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:item_prices]) }
  let(:item_prices) { create_list(:item_price, 10) }

  before do
    sign_in user if user.present?

    item_prices
  end

  path "/item-prices" do
    get("Item Prices list") do
      operationId "itemPrices"
      tags "ItemPrices"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ItemPrice.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ItemPriceQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ItemPrices"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(10)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ItemPrices"

        let(:q) do
          {
            "itemIdEq" => item_prices.first.item_id
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
        end
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

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
