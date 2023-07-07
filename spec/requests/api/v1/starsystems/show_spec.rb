# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/starsystems", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:starsystem) { starsystems :stanton }

  path "/starsystems/{slug}" do
    parameter name: "slug", in: :path, description: "Starsystem slug", schema: {type: :string}, required: true

    get("Starsystem Detail") do
      operationId "get"
      tags "Starsystems"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/StarsystemMinimal"

        let(:slug) { starsystem.slug }

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
