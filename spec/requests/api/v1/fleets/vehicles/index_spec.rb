# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:model_alpha) { create(:model, name: "Alpha") }
  let(:model_bravo) { create(:model, name: "Bravo") }
  let(:model_charlie) { create(:model, name: "Charlie") }
  let(:admin) { create(:user, vehicle_count: 0) }
  let(:member) { create(:user, vehicle_count: 0) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
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
    Sidekiq::Testing.inline!

    create(:vehicle, user: admin, model: model_alpha)
    create(:vehicle, user: admin, model: model_charlie)
    create(:vehicle, user: member, model: model_bravo)

    sign_in(user) if user.present?
  end

  after do
    Sidekiq::Testing.fake!
  end

  path "/fleets/{fleetSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Vehicles List") do
      operationId "fleetVehicles"
      tags "Fleets"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "grouped", in: :query, type: :boolean, required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetVehicles"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(3)
        end

        context "with filter" do
          let(:q) do
            {
              "modelNameCont" => fleet.models.first.name
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            items = data["items"]

            expect(items.count).to eq(1)
            expect(items.first.dig("model", "name")).to eq(fleet.models.first.name)
          end
        end

        context "with perPage" do
          let(:perPage) { 1 }

          run_test! do |response|
            data = JSON.parse(response.body)
            items = data["items"]

            expect(items.count).to eq(1)
          end
        end

        context "with grouped flag" do
          let(:grouped) { true }

          run_test! do |response|
            data = JSON.parse(response.body)
            items = data["items"]

            expect(items.count).to eq(3)
          end
        end

        context "with member" do
          let(:user) { member }

          run_test! do |response|
            data = JSON.parse(response.body)
            items = data["items"]

            expect(items.count).to be > 0
            expect(items.count).to eq(3)
          end
        end

        context "sorted by modelName asc" do
          let(:q) { {"sorts" => "modelName asc"} }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data["items"].map { |m| m.dig("model", "name") }

            expect(names).to eq(%w[Alpha Bravo Charlie])
          end
        end

        context "sorted by modelName desc" do
          let(:q) { {"sorts" => "modelName desc"} }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data["items"].map { |m| m.dig("model", "name") }

            expect(names).to eq(%w[Charlie Bravo Alpha])
          end
        end

        context "sorted by modelName asc via s param" do
          let(:q) { {"s" => "modelName asc"} }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data["items"].map { |m| m.dig("model", "name") }

            expect(names).to eq(%w[Alpha Bravo Charlie])
          end
        end

        context "sorted by modelName asc grouped" do
          let(:q) { {"sorts" => "modelName asc"} }
          let(:grouped) { true }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data["items"].map { |m| m["name"] }

            expect(names).to eq(%w[Alpha Bravo Charlie])
          end
        end

        context "sorted by modelName desc grouped" do
          let(:q) { {"sorts" => "modelName desc"} }
          let(:grouped) { true }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data["items"].map { |m| m["name"] }

            expect(names).to eq(%w[Charlie Bravo Alpha])
          end
        end
      end

      include_examples "oauth_auth"

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end
    end
  end
end
