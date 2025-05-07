# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:fleet_admin) { create(:fleet, admins: [user]) }
  let(:fleet_member) { create(:fleet, members: [user]) }
  let(:fleet_other) { create(:fleet) }
  let(:fleet_hidden) { create(:fleet, public_fleet: false) }

  before do
    sign_in(user) if user.present?
  end

  path "/public/fleets/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Detail") do
      operationId "publicFleet"
      tags "Fleets"
      produces "application/json"

      response(200, "successful for admin of fleet") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet_admin.slug }

        run_test!
      end

      response(200, "successful for member of fleet") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet_member.slug }

        run_test!
      end

      response(200, "successful for other fleet") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet_other.slug }

        run_test!
      end

      response(200, "successful without seesion") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet_other.slug }
        let(:user) { nil }

        run_test!
      end

      response(404, "not found if fleet is not public") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { fleet_hidden.slug }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-fleet" }

        run_test!
      end
    end
  end
end
