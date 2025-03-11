# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/invite_urls", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  let(:fleet) { fleets :starfleet }
  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/invite-urls" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    post("Create Fleet Invite Url") do
      operationId "createFleetInviteUrl"
      tags "FleetInviteUrls"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetInviteUrlCreateInput"}, required: true

      let(:input) do
        {
          expiresAfterMinutes: 60
        }
      end

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetInviteUrl"

        let(:user) { users :jeanluc }

        before do
          travel_to Time.utc(2305, 6, 13, 12, 0, 0)
        end

        after do |example|
          travel_back
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["expiresAfter"]).to eq("2305-06-13T13:00:00Z")
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { users :jeanluc }
        let(:input) do
          {
            limit: -100
          }
        end

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :jeanluc }
        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :data }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
