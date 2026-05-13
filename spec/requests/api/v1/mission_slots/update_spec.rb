# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/mission_slots", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:team) { create(:mission_team, mission: mission) }
  let(:slot) { create(:mission_slot, slottable: team) }
  let(:id) { slot.id }
  let(:input) { {title: "Co-Pilot"} }

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
    parameter name: "id", in: :path, type: :string

    put("Update Mission Slot") do
      operationId "updateMissionSlot"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/MissionSlotUpdateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/MissionSlot"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to eq("Co-Pilot")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
