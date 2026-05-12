# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/me/calendar/subscription", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:account) { create(:user) }
  let(:user) { account }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: account.id, scopes: ["user", "user:write"])
  end
  let(:wrong_scope_access_token) do
    create(:oauth_access_token, resource_owner_id: account.id, scopes: ["public"])
  end

  before do
    Flipper.enable("mission_builder")
    sign_in(user) if user.present?
  end

  path "/me/calendar/subscription" do
    post("Generate personal calendar subscription") do
      operationId "createMyCalendarSubscription"
      tags "Me Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CalendarSubscription"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["enabled"]).to be(true)
          expect(data["feedUrl"]).to include("token=")
          expect(account.reload.calendar_feed_token).to be_present
        end
      end

      include_examples "oauth_auth"
    end

    delete("Disable personal calendar subscription") do
      operationId "destroyMyCalendarSubscription"
      tags "Me Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      before { account.ensure_calendar_feed_token! }

      response(204, "successful") do
        run_test! do
          expect(account.reload.calendar_feed_token).to be_nil
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end

  path "/me/calendar/subscription/rotate" do
    post("Rotate personal calendar subscription") do
      operationId "rotateMyCalendarSubscription"
      tags "Me Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CalendarSubscription"

        before do
          account.ensure_calendar_feed_token!
          @old_token = account.reload.calendar_feed_token
        end

        run_test! do |response|
          new_token = account.reload.calendar_feed_token
          expect(new_token).to be_present
          expect(new_token).not_to eq(@old_token)
        end
      end

      include_examples "oauth_auth"
    end
  end
end
