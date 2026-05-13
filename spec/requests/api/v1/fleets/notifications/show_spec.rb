# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/notifications", type: :request, swagger_doc: "v1/schema.yaml" do
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
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/notifications" do
    parameter name: "fleetSlug", in: :path, type: :string

    get("Show fleet notification settings") do
      operationId "fleetNotificationSetting"
      tags "Fleet Notification Settings"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetNotificationSetting"
        run_test!
      end

      include_examples "oauth_auth"
    end
  end
end
