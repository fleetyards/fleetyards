# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/roles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/roles" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Role List") do
      operationId "fleetRoles"
      tags "FleetRoles"
      produces "application/json"

      security [{
        SessionCookie: [],
        Oauth2: ["fleet", "fleet:read"],
        OpenId: ["fleet", "fleet:read"]
      }]

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FleetRoleExtended"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.first).to have_key("name")
          expect(data.first).to have_key("resourceAccess")
          expect(data.first).to have_key("permanent")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

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
