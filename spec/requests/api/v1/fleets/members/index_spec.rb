# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/members", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:another_member) { create(:user) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], members: [member, another_member]) }
  let(:fleetSlug) { fleet.slug }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["fleet", "fleet:read"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/members" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Member List") do
      operationId "fleetMembers"
      tags "FleetMembers"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetMemberQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMembersList"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to be > 0
          expect(data["items"].count).to eq(3)
        end

        context "with filter" do
          let(:q) do
            {
              "usernameCont" => member.username
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].count).to eq(1)
            expect(data["items"].first.dig("username")).to eq(member.username)
          end
        end

        context "with perPage" do
          let(:perPage) { 1 }

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].count).to eq(1)
          end
        end

        context "with member" do
          let(:user) { member }

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].count).to eq(3)
          end
        end

        context "sorted by rsiHandle asc" do
          let(:q) do
            {
              "sorts" => "rsiHandle asc"
            }
          end

          before do
            admin.update!(rsi_handle: "charlie")
            member.update!(rsi_handle: "alpha")
            another_member.update!(rsi_handle: "bravo")
          end

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].count).to eq(3)
            expect(data["items"].map { |m| m["rsiHandle"] }).to eq(%w[alpha bravo charlie])
          end
        end

        context "sorted by rsiHandle desc" do
          let(:q) do
            {
              "sorts" => "rsiHandle desc"
            }
          end

          before do
            admin.update!(rsi_handle: "charlie")
            member.update!(rsi_handle: "alpha")
            another_member.update!(rsi_handle: "bravo")
          end

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].count).to eq(3)
            expect(data["items"].map { |m| m["rsiHandle"] }).to eq(%w[charlie bravo alpha])
          end
        end
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
