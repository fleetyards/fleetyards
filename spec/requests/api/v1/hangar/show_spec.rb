# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/hangar" do
    get("Your personal Hangar") do
      operationId "get"
      tags "Hangar"
      produces "application/json"

      parameter name: "page", in: :query, type: :number, required: false, default: 1
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
        schema "$ref": "#/components/schemas/Hangar"

        let(:user) { users :data }

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
        schema "$ref": "#/components/schemas/Hangar"

        let(:user) { users :data }
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
        schema "$ref": "#/components/schemas/Hangar"

        let(:user) { users :data }
        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
