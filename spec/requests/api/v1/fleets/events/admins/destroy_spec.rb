# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/events/admins", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:other) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [other]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }
  let(:slug) { fleet_event.slug }
  let(:granted) do
    fleet_event.fleet_event_admins.create!(user: other, role: "admin", granted_by: admin)
  end
  let(:id) { granted.id }

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

  path "/fleets/{fleetSlug}/events/{slug}/admins/{id}" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string
    parameter name: "id", in: :path, type: :string

    delete("Revoke per-event admin/moderator role") do
      operationId "destroyFleetEventAdmin"
      tags "Fleet Event Admins"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect { granted.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
