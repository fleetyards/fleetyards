# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/events", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["fleet", "fleet:read"])
  end
  let(:wrong_scope_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["public"])
  end

  before do
    Flipper.enable("mission_builder")
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/events" do
    parameter name: "fleetSlug", in: :path, type: :string

    get("List Fleet Events") do
      operationId "fleetEvents"
      tags "Fleet Events"
      produces "application/json"

      parameter name: :upcoming, in: :query, type: :boolean, required: false
      parameter name: :past, in: :query, type: :boolean, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventsList"

        before do
          create_list(:fleet_event, 2, fleet: fleet, created_by: admin)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(2)
        end
      end

      include_examples "oauth_auth"
    end
  end
end
