# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/fleets/:fleet_id/members/:id/login-as", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:fleets]) }
  let(:fleet) { create(:fleet, members: [member_user]) }
  let(:member_user) { create(:user) }
  let(:fleet_id) { fleet.id }
  let(:id) { fleet.fleet_memberships.first.id }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleet_id}/members/{id}/login-as" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Fleet Member id", schema: {type: :string, format: :uuid}

    get("Login as Fleet Member") do
      operationId "loginAsFleetMember"
      tags "FleetMembers"
      produces "application/json"

      response(204, "successful") do
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
