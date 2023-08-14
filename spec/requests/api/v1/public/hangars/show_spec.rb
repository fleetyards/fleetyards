# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/hangars", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { users :data }
  let(:user_without_public_hangar) { users :troi }

  path "/public/hangars/{username}" do
    parameter name: "username", in: :path, type: :string, required: true

    get("Public Hangar") do
      operationId "publicHangar"
      tags "PublicHangar"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Vehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}

        let(:username) { user.username }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}

        let(:perPage) { 1 }
        let(:username) { user.username }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { user_without_public_hangar.username }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { "not-a-user" }

        run_test!
      end
    end
  end
end
