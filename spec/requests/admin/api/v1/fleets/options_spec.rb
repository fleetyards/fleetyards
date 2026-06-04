# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/fleets", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:fleets]) }

  let!(:fleets) { create_list(:fleet, 6) }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/options" do
    get("Fleet Options") do
      operationId "fleetOptions"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/FleetQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetOptions"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(6)
          expect(items.first.keys).to match_array(%w[id fid name slug])
        end
      end

      include_examples "admin_auth"
    end
  end
end
