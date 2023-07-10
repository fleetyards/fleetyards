# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/hangars", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { users :data }
  let(:user_without_public_hangar) { users :troi }

  path "/public/hangars/{username}" do
    parameter name: "username", in: :path, type: :string, required: true

    get("Public Hangar") do
      operationId "get"
      tags "PublicHangar"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false, default: Vehicle.default_per_page
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarPublic"

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
          items = data["items"]

          expect(items.count).to be > 0
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarPublic"

        let(:username) { user.username }
        let(:q) do
          {
            "modelNameOrModelDescriptionCont" => "Andromeda"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first.dig("model", "name")).to eq("Andromeda")
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarPublic"

        let(:username) { user.username }
        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
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
