# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/public/hangars/stats", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user, public_hangar_stats: true, vehicle_count: 3) }
  let(:username) { user.username }

  path "/public/hangars/{username}/stats/models-by-size" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "username"

    get("Public Hangar Models by Size") do
      operationId "publicHangarModelsBySize"
      tags "PublicHangarStats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user, public_hangar_stats: false) }

        run_test!
      end
    end
  end
end
