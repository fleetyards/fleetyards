# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/stats", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:user) { admin_users :jeanluc }

  before do
    sign_in(user) if user.present?
  end

  path "/stats/registrations-per-month" do
    get("Stats Registrations per Month") do
      operationId "registrationsPerMonth"
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
