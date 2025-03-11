# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/filters/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/filters/vehicles/bought-via" do
    get("Vehicles Bought Via Filters") do
      operationId "vehicleBoughtViaFilters"
      tags "VehicleFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}

        run_test!
      end
    end
  end
end
