# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/item_prices", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:user) { admin_users :jeanluc }
  let(:data) do
    {
      itemId: models(:andromeda).id,
      itemType: "Model",
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

      parameter name: :data, in: :body, schema: {"$ref": "#/components/schemas/ItemPriceInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ItemPrice"

        run_test!
      end

      response(400, "unauthorized") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:data) { nil }

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
