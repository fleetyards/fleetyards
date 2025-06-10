# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/hangars", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:usernames) do
    [user.username]
  end
  let(:vehicles) { create_list(:vehicle, 2, user: user, public: true) }

  before do
    vehicles
  end

  path "/public/hangars/embed" do
    get("Public Hangar embed") do
      operationId "publicHangarEmbed"
      tags "PublicHangar"
      produces "application/json"

      parameter name: :usernames, in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarEmbedQuery"
        },
        style: :deepObject,
        explode: true,
        required: true

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
      end

      response(200, "empty response") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}

        let(:user) { create(:user, public_hangar: false) }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be == 0
        end
      end

      response(200, "empty response") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}

        let(:usernames) do
          ["not-a-user"]
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be == 0
        end
      end
    end
  end
end
