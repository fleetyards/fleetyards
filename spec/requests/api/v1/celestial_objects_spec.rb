# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/celestial_objects", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :celestial_objects

  before do
    host! "api.fleetyards.test"
  end

  path "/celestial-objects" do
    get("Celestial Objects List") do
      description "Get a List of Celestial Objects"
      tags "CelestialObjects"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/CelestialObject"}

        run_test!
      end
    end
  end

  path "/celestial-objects/{slug}" do
    get("Celestial Object Detail") do
      parameter name: "slug", in: :path, description: "slug", schema: {type: :string}

      description "Get Detail of a Celestial Object referenced by its Slug"
      tags "CelestialObjects"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/CelestialObject"

        let(:crusader) { celestial_objects :crusader }
        let(:slug) { crusader.slug }

        run_test!
      end

      response(404, "not_found") do
        schema "$ref" => "#/components/schemas/StandardError"

        let(:slug) { "unknown_slug" }

        run_test!
      end
    end
  end
end
