# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/events/{slug}/update-occurrence", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_event) do
    create(:fleet_event, :open,
      fleet: fleet, created_by: admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
  end
  let(:slug) { fleet_event.slug }
  let(:input) do
    {date: "2026-05-21", location: "Levski", scenario: "Bunker raid"}
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["fleet", "fleet:write"])
  end
  let(:wrong_scope_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["public"])
  end

  before do
    Flipper.enable("mission_builder")
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/events/{slug}/update-occurrence" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    patch("Override fields on a single occurrence") do
      operationId "updateFleetEventOccurrence"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          date: {type: :string, format: :date},
          title: {type: :string, nullable: true},
          description: {type: :string, nullable: true},
          briefing: {type: :string, nullable: true},
          location: {type: :string, nullable: true},
          meetupLocation: {type: :string, nullable: true},
          scenario: {type: :string, nullable: true},
          coverImagePreset: {type: :string, nullable: true}
        },
        required: %w[date]
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventOccurrenceState"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["location"]).to eq("Levski")
          expect(data["scenario"]).to eq("Bunker raid")
        end
      end
    end
  end
end
