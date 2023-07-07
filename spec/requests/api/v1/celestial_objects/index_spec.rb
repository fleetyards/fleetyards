# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/celestial_objects", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :celestial_objects

  path "/celestial-objects" do
    get("Celestial Objects List") do
      operationId "list"
      description "Get a List of Celestial Objects"
      tags "CelestialObjects"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/CelestialObjectMinimal"}

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
