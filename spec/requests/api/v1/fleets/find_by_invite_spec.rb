# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:fleet) { create(:fleet) }
  let(:fleet_invite_url) { create(:fleet_invite_url, fleet:) }
  let(:token) { fleet_invite_url.token }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/find-by-invite/{token}" do
    parameter name: "token", in: :path, type: :string, description: "Fleet Invite Token"

    post("Find Fleet by Invite") do
      operationId "findFleetByInvite"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["id"]).to eq(fleet.id)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
