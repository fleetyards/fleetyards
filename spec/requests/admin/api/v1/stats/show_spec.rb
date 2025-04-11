# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/stats", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:stats]) }

  before do
    sign_in(user) if user.present?
  end

  path "/stats/quick-stats" do
    get("Stats") do
      operationId "stats"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Stats"

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
