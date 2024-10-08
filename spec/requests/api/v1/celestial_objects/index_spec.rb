# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/celestial_objects", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/celestial-objects" do
    get("Celestial Objects List") do
      operationId "celestialObjects"
      description "Get a List of Celestial Objects"
      tags "CelestialObjects"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: CelestialObject.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/CelestialObjectQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/CelestialObject"}

        after do |example|
          if response&.body.present?
            example.metadata[:response][:content] = {
              "application/json": {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
      end
    end
  end
end
