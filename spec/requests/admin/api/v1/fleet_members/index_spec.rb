# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/fleets/:fleet_id/members", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:fleets]) }
  let(:fleet) { create(:fleet, members: create_list(:user, 3)) }
  let(:fleet_id) { fleet.id }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleet_id}/members" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    get("Fleet Members list") do
      operationId "fleetMembers"
      tags "FleetMembers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/AdminFleetMemberQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminFleetMembers"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleet_id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
