# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/calendar/subscription", type: :request, swagger_doc: "v1/schema.yaml" do
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

  path "/fleets/{fleetSlug}/calendar/subscription" do
    parameter name: "fleetSlug", in: :path, type: :string

    get("Show calendar subscription") do
      operationId "fleetCalendarSubscription"
      tags "Fleet Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful (disabled)") do
        schema "$ref": "#/components/schemas/CalendarSubscription"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["enabled"]).to be(false)
          expect(data["feedUrl"]).to be_nil
        end
      end

      response(200, "successful (enabled)") do
        before { fleet.ensure_calendar_feed_token! }
        schema "$ref": "#/components/schemas/CalendarSubscription"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["enabled"]).to be(true)
          expect(data["feedUrl"]).to include("events.ics")
          expect(data["feedUrl"]).to include("token=")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
