# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/mission_slots", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:team) { create(:mission_team, mission: mission) }
  let(:slot) { create(:mission_slot, slottable: team) }
  let(:id) { slot.id }

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

  path "/mission-slots/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}

    delete("Destroy Mission Slot") do
      operationId "destroyMissionSlot"
      tags "Missions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect { slot.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
