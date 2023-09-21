# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }
  let(:fleet) { fleets(:starfleet) }
  let(:fleet_invite_url) { fleet_invite_urls(:starfleet_invite) }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/find-by-invite/{token}" do
    parameter name: "token", in: :path, type: :string, description: "Fleet Invite Token"

    post("Find Fleet by Invite") do
      operationId "findByInvite"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:user) { users :data }
        let(:token) { fleet_invite_url.token }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["id"]).to eq(fleet.id)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:token) { fleet_invite_url.token }

        run_test!
      end
    end
  end
end
