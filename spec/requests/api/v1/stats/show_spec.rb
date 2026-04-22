# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/stats", type: :openapi, openapi_schema_name: :"v1/schema" do
  path "/stats/quick-stats" do
    get("Stats") do
      operationId "stats"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Stats"

        run_test!
      end
    end
  end
end
