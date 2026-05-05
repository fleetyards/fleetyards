# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/events", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }
  let(:slug) { fleet_event.slug }

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

  path "/fleets/{fleetSlug}/events/{slug}/publish" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    put("Publish Fleet Event") do
      operationId "publishFleetEvent"
      tags "Fleet Events"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("open")
          expect(fleet_event.reload.status).to eq("open")
        end
      end

      response(400, "invalid state transition") do
        let(:fleet_event) { create(:fleet_event, :active, fleet: fleet, created_by: admin) }

        run_test!
      end

      include_examples "oauth_auth"
    end
  end

  path "/fleets/{fleetSlug}/events/{slug}/lock-signups" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    put("Lock Signups") do
      operationId "lockFleetEventSignups"
      tags "Fleet Events"
      produces "application/json"

      let(:fleet_event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("locked")
        end
      end

      include_examples "oauth_auth"
    end
  end

  path "/fleets/{fleetSlug}/events/{slug}/unlock-signups" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    put("Unlock Signups") do
      operationId "unlockFleetEventSignups"
      tags "Fleet Events"
      produces "application/json"

      let(:fleet_event) { create(:fleet_event, :locked, fleet: fleet, created_by: admin) }

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("open")
        end
      end

      include_examples "oauth_auth"
    end
  end

  path "/fleets/{fleetSlug}/events/{slug}/start" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    put("Start Fleet Event") do
      operationId "startFleetEvent"
      tags "Fleet Events"
      produces "application/json"

      let(:fleet_event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("active")
        end
      end

      include_examples "oauth_auth"
    end
  end

  path "/fleets/{fleetSlug}/events/{slug}/complete" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    put("Complete Fleet Event") do
      operationId "completeFleetEvent"
      tags "Fleet Events"
      produces "application/json"

      let(:fleet_event) { create(:fleet_event, :active, fleet: fleet, created_by: admin) }

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("completed")
        end
      end

      include_examples "oauth_auth"
    end
  end

  path "/fleets/{fleetSlug}/events/{slug}/unarchive" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    put("Unarchive Fleet Event") do
      operationId "unarchiveFleetEvent"
      tags "Fleet Events"
      produces "application/json"

      let(:fleet_event) do
        event = create(:fleet_event, fleet: fleet, created_by: admin)
        event.archive!
        event
      end

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["archived"]).to eq(false)
        end
      end

      response(400, "not archived") do
        let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }

        run_test!
      end

      include_examples "oauth_auth"
    end
  end

  path "/fleets/{fleetSlug}/events/{slug}/cancel" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    put("Cancel Fleet Event") do
      operationId "cancelFleetEvent"
      tags "Fleet Events"
      produces "application/json"

      let(:fleet_event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("cancelled")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
