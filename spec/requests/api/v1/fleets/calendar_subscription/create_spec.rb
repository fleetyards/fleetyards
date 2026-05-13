# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/calendar/subscription", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }

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

  path "/fleets/{fleetSlug}/calendar/subscription" do
    parameter name: "fleetSlug", in: :path, type: :string

    post("Generate calendar subscription token") do
      operationId "createFleetCalendarSubscription"
      tags "Fleet Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CalendarSubscription"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["enabled"]).to be(true)
          expect(data["feedUrl"]).to include("token=")
          expect(fleet.reload.calendar_feed_token).to be_present
        end
      end

      response(200, "idempotent when already enabled") do
        before { fleet.ensure_calendar_feed_token! }
        let(:existing_token) { fleet.reload.calendar_feed_token }

        run_test! do |response|
          expect(fleet.reload.calendar_feed_token).to eq(existing_token)
        end
      end

      include_examples "oauth_auth"
    end

    delete("Disable calendar subscription") do
      operationId "destroyFleetCalendarSubscription"
      tags "Fleet Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      before { fleet.ensure_calendar_feed_token! }

      response(204, "successful") do
        run_test! do
          expect(fleet.reload.calendar_feed_token).to be_nil
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end

  path "/fleets/{fleetSlug}/calendar/subscription/rotate" do
    parameter name: "fleetSlug", in: :path, type: :string

    post("Rotate calendar subscription token") do
      operationId "rotateFleetCalendarSubscription"
      tags "Fleet Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CalendarSubscription"

        before do
          fleet.ensure_calendar_feed_token!
          @old_token = fleet.reload.calendar_feed_token
        end

        run_test! do |response|
          new_token = fleet.reload.calendar_feed_token
          expect(new_token).to be_present
          expect(new_token).not_to eq(@old_token)
        end
      end

      include_examples "oauth_auth"
    end
  end
end
