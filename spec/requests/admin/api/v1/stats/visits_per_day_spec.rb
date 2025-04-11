# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/stats", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:stats]) }

  before do
    sign_in(user) if user.present?
  end

  path "/stats/visits-per-day" do
    get("Stats Visits per Day") do
      operationId "visitsPerDay"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/BarChartStats"}

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
