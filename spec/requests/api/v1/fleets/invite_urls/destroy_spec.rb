# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/invite_urls", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }
  let(:invite_url) { fleet_invite_urls :starfleet_invite }

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/invite-urls/{token}" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "token", in: :path, type: :string, description: "Invite Url Token"

    delete("Remove Invite Url") do
      operationId "removeInviteUrl"
      tags "FleetInviteUrls"
      produces "application/json"

      response(204, "successful") do
        let(:user) { users :jeanluc }
        let(:fleetSlug) { fleet.slug }
        let(:token) { invite_url.token }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :jeanluc }
        let(:fleetSlug) { "unknown-fleet" }
        let(:token) { invite_url.token }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :jeanluc }
        let(:fleetSlug) { fleet.slug }
        let(:token) { "unknown-token" }

        run_test!
      end

      response(403, "forbidden") do
        description "You are not the owner of this Fleet"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :data }
        let(:fleetSlug) { fleet.slug }
        let(:token) { invite_url.token }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { fleet.slug }
        let(:token) { invite_url.token }

        run_test!
      end
    end
  end
end
