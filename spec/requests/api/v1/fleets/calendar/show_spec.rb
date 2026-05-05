# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/calendar", type: :request, swagger_doc: "v1/schema.yaml" do
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

  path "/fleets/{fleetSlug}/calendar" do
    parameter name: "fleetSlug", in: :path, type: :string

    get("Fleet Calendar") do
      operationId "fleetCalendar"
      tags "Fleet Events"
      produces "application/json"

      parameter name: :from, in: :query, type: :string, required: false
      parameter name: :to, in: :query, type: :string, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :object, properties: {
          items: {type: :array, items: {"$ref": "#/components/schemas/FleetEvent"}}
        }, required: %w[items]

        before do
          create(:fleet_event, fleet: fleet, created_by: admin, starts_at: 1.day.from_now)
          create(:fleet_event, fleet: fleet, created_by: admin, starts_at: 5.days.from_now)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to be >= 2
        end
      end

      include_examples "oauth_auth"
    end
  end
end
