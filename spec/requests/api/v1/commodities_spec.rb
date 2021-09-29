# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/commodities", type: :request, swagger_doc: "v1.yaml" do
  fixtures :commodities

  before do
    host! "api.fleetyards.test"
  end

  path "/commodities" do
    get("list commodities") do
      description "Get a List of Commodities"
      tags "Commodities"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/Commodity"}

        run_test!
      end
    end
  end

  path "/commodities/types" do
    get("commodity_types commodity") do
      description "Get a List of all Commodity Types"
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
