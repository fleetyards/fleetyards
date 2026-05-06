# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/notifications", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:input) do
    {
      discordGuildId: "123456789012345678",
      discordChannelId: "234567890123456789",
      enabledInAppEvents: ["fleet_event.published"],
      enabledDiscordEvents: ["fleet_event.published", "fleet_event.cancelled"]
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["fleet", "fleet:write"])
  end
  let(:wrong_scope_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["public"])
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/notifications" do
    parameter name: "fleetSlug", in: :path, type: :string

    patch("Update fleet notification settings") do
      operationId "updateFleetNotificationSetting"
      tags "Fleet Notification Settings"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          discordGuildId: {type: :string, nullable: true},
          discordChannelId: {type: :string, nullable: true},
          discordWebhookUrl: {type: :string, nullable: true},
          enabledInAppEvents: {type: :array, items: {type: :string}},
          enabledDiscordEvents: {type: :array, items: {type: :string}}
        }
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetNotificationSetting"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["discordGuildId"]).to eq("123456789012345678")
          expect(data["enabledDiscordEvents"]).to include("fleet_event.cancelled")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
