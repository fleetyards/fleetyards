# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user, vehicle_count: 2) }
  let(:fleet) { create(:fleet, members: [member]) }
  let(:user) { member }
  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/stats/members" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Members Stats") do
      operationId "fleetMembersStats"
      tags "FleetStats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetMembersStats"

        run_test!
      end
    end
  end
end
