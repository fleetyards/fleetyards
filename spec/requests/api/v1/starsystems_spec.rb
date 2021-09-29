# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/starsystems", type: :request, swagger_doc: "v1.yaml" do
  fixtures :starsystems

  before do
    host! "api.fleetyards.test"
  end

  path "/starsystems" do
    get("list starsystems") do
      description "Get a List of Starsystems"
      tags "Starsystems"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/Starsystem"}

        run_test!
      end
    end
  end

  path "/starsystems/{slug}" do
    get("show starsystem") do
      parameter name: "slug", in: :path, description: "slug", schema: {type: :string}

      description "Get Detail of a Starsystem referenced by its Slug"
      tags "Starsystems"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/Starsystem"

        let(:stanton) { starsystems :stanton }
        let(:slug) { stanton.slug }

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
