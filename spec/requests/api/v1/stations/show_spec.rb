# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/stations", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:station) { stations :portolisar }

  path "/stations/{slug}" do
    parameter name: "slug", in: :path, description: "Station slug", schema: {type: :string}, required: true

    get("Station Detail") do
      operationId "get"
      tags "Stations"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/StationComplete"

        let(:slug) { station.slug }

        run_test!
      end

      response(404, "not_found") do
        schema "$ref" => "#/components/schemas/StandardError"

        let(:slug) { "unknown_slug" }

        run_test!
      end
    end
  end

  path "/stations/{slug}/images" do
    parameter name: "slug", in: :path, description: "Station slug", schema: {type: :string}, required: true

    get("Station Images") do
      operationId "images"
      tags "Stations"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false,
        default: Image.default_per_page

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/ImageComplete"}

        let(:slug) { station.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

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
