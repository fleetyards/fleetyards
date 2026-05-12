# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/me/calendar/subscription", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:account) { create(:user) }
  let(:user) { account }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: account.id, scopes: ["user", "user:read"])
  end
  let(:wrong_scope_access_token) do
    create(:oauth_access_token, resource_owner_id: account.id, scopes: ["public"])
  end

  before do
    Flipper.enable("mission_builder")
    sign_in(user) if user.present?
  end

  path "/me/calendar/subscription" do
    get("Show personal calendar subscription") do
      operationId "myCalendarSubscription"
      tags "Me Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
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
        before { account.ensure_calendar_feed_token! }
        schema "$ref": "#/components/schemas/CalendarSubscription"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["enabled"]).to be(true)
          expect(data["feedUrl"]).to include("/me/calendar/events.ics")
          expect(data["feedUrl"]).to include("token=")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
