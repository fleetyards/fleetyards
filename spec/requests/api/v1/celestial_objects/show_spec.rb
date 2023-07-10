# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/celestial_objects", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :celestial_objects

  path "/celestial-objects/{slug}" do
    parameter name: "slug", in: :path, description: "slug", schema: {type: :string}

    get("Celestial Object Detail") do
      operationId "get"
      description "Get Detail of a Celestial Object referenced by its Slug"
      tags "CelestialObjects"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CelestialObjectMinimal"

        let(:crusader) { celestial_objects :crusader }
        let(:slug) { crusader.slug }

        after do |example|
          if response&.body.present?
            example.metadata[:response][:content] = {
              "application/json": {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
        end

        run_test!
      end

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown_slug" }

        run_test!
      end
    end
  end
end
