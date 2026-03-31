# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/fleets", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:fleets]) }

  before do
    create_list(:fleet, 3)
    sign_in(user) if user.present?
  end

  path "/fleets" do
    get("Fleets list") do
      operationId "fleets"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/FleetQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleets"

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

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
