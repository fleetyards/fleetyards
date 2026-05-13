# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/missions", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:slug) { mission.slug }

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

  path "/fleets/{fleetSlug}/missions/{slug}" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    delete("Archive Mission") do
      operationId "destroyFleetMission"
      tags "Missions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful - archived") do
        schema "$ref": "#/components/schemas/MissionExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["archived"]).to eq(true)
          expect(mission.reload.archived?).to be(true)
        end
      end

      response(204, "successful - permanent delete on already-archived mission") do
        let(:mission) { create(:mission, :archived, fleet: fleet, created_by: admin) }

        run_test! do
          expect { mission.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      include_examples "oauth_auth"
    end
  end
end
