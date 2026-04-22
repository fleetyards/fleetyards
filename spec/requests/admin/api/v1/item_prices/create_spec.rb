# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/item_prices", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:item_prices]) }
  let(:item) { create(:model) }
  let(:request_body) do
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

      request_body required: true, schema: {"$ref": "#/components/schemas/ItemPriceInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ItemPrice"

        run_test!
      end

      response(400, "unauthorized") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { nil }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
