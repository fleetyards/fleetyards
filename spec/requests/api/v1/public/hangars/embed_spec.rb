# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/hangars", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { users :data }
  let(:user_without_public_hangar) { users :troi }

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

        let(:usernames) do
          [user.username]
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
      end

      response(200, "empty response") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}

        let(:usernames) do
          [user_without_public_hangar.username]
        end

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
