# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/invite_urls", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user) }
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, members: [member], admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:invite_url) { create(:fleet_invite_url, fleet: fleet, user: admin) }
  let(:token) { invite_url.token }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/invite-urls/{token}" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "token", in: :path, type: :string, description: "Invite Url Token"

    delete("Remove Fleet Invite Url") do
      operationId "destroyFleetInviteUrl"
      tags "FleetInviteUrls"
      produces "application/json"

      response(204, "successful") do
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:token) { "unknown-token" }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { member }

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
