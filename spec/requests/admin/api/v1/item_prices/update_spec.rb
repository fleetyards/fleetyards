# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/item_prices", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:user) { admin_users :jeanluc }
  let(:item_price) { item_prices :andromeda_item_price }
  let(:id) { item_price.id }
  let(:data) do
    {
      price: 500
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/item-prices/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Item Price") do
      operationId "updateItemPrice"
      tags "ItemPrices"

      consumes "application/json"
      produces "application/json"

      parameter name: :data, in: :body, schema: {"$ref": "#/components/schemas/ItemPriceInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ItemPrice"

        run_test!
      end

      response(400, "unauthorized") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:data) do
          {
            price_type: "foo"
          }
        end

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "foo" }

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
