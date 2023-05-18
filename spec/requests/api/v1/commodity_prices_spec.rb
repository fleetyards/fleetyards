# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/commodity_prices", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :users

  before do
    host! "api.fleetyards.test"
  end

  path "/commodity-prices" do
    post("create commodity_price") do
      description "Create new CommodityPrice"
      tags "Commodities"
      consumes "application/json"
      produces "application/json"

      context "without session" do
        response(401, "unauthorized") do
          schema "$ref" => "#/components/schemas/StandardError"

          run_test!
        end
      end

      context "with session" do
        let(:data) { users :data }

        before do
          sign_in data
        end

        response(200, "successful") do
          schema "$ref" => "#/components/schemas/CommodityPrice"

          run_test!
        end

        response(400, "invalid data") do
          schema "$ref" => "#/components/schemas/ValidationError"

          run_test!
        end
      end
    end
  end

  path "/commodity-prices/time-ranges" do
    get("time_ranges commodity_price") do
      description "Get a List of all Commodity Price TimeRanges"
      tags "Commodities"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/FilterOption"}

        run_test!
      end
    end
  end
end
