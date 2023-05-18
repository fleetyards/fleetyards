# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/trade_routes", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/trade-routes" do
    get("list trade_routes") do
      tags "TradeRoutes"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end
end
