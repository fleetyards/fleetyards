# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/item_prices", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:item_prices]) }
  let(:item) { create(:model) }
  let(:input) do
    {
      itemId: item.id,
      itemType: item.class.name,
      price: 1000.50,
      priceType: "buy",
      location: "Port Olisar"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/item-prices" do
    post("Create new Item Price") do
      operationId "createItemPrice"
      tags "ItemPrices"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ItemPriceInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ItemPrice"

        run_test!
      end

      response(400, "unauthorized") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { nil }

        run_test!
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
