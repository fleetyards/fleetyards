# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    put("Update Fleet") do
      operationId "updateFleet"
      tags "Fleets"
      consumes "multipart/form-data"
      produces "application/json"

      parameter name: :"", in: :formData, schema: {"$ref": "#/components/schemas/FleetUpdateInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet.slug }
        let(:user) { users :jeanluc }
        let(:"") do
          {
            discord: "https://discord.gg/1234567890"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["discord"]).to eq("discord.gg/1234567890")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-model" }
        let(:user) { users :data }
        let(:"") { nil }

        run_test!
      end

      response(403, "forbidden") do
        description "You are not an Admin or Officer of this Fleet"
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { fleet.slug }
        let(:user) { users :data }
        let(:"") { nil }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { fleet.slug }
        let(:"") { nil }

        run_test!
      end
    end
  end
end
