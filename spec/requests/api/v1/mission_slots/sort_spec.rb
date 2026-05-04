# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/mission_slots", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:team) { create(:mission_team, mission: mission) }
  let!(:slots) { create_list(:mission_slot, 3, slottable: team) }
  let(:input) do
    {
      slottableType: "MissionTeam",
      slottableId: team.id,
      sorting: slots.reverse.map(&:id)
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
    Flipper.enable("mission_builder")
    sign_in(user) if user.present?
  end

  path "/mission-slots/sort" do
    put("Sort Mission Slots") do
      operationId "sortMissionSlots"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/MissionSlotSortInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema type: :object, properties: {success: {type: :boolean}}

        run_test! do
          slots.reverse.each_with_index do |slot, index|
            expect(slot.reload.position).to eq(index)
          end
        end
      end

      include_examples "oauth_auth"
    end
  end
end
