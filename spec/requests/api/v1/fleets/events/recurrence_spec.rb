# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/events/{slug}", type: :request, swagger_doc: "v1/schema.yaml" do
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
  let(:input) { {date: "2026-05-21"} }

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

  path "/fleets/{fleetSlug}/events/{slug}/skip-occurrence" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    post("Skip a specific occurrence of a recurring event") do
      operationId "skipFleetEventOccurrence"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {date: {type: :string, format: :date}},
        required: %w[date]
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do
          expect(fleet_event.reload.excluded_dates.map(&:to_s))
            .to include("2026-05-21")
        end
      end

      response(422, "not recurring") do
        let(:fleet_event) do
          create(:fleet_event, :open, fleet: fleet, created_by: admin,
            recurring: false)
        end
        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/events/{slug}/end-series" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    post("End a recurring event series from a given date") do
      operationId "endFleetEventSeries"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {date: {type: :string, format: :date}},
        required: %w[date]
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        let(:input) { {date: "2026-06-04"} }
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do
          expect(fleet_event.reload.recurrence_until).to eq(Date.parse("2026-06-03"))
        end
      end
    end
  end
end
