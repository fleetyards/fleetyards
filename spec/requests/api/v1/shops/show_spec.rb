# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/shops", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:station) { stations :portolisar }
  let(:shop) { shops :dumpers }

  path "/stations/{stationSlug}/shops/{slug}" do
    parameter name: "stationSlug", in: :path, type: :string, description: "Station slug", required: true
    parameter name: "slug", in: :path, type: :string, description: "Shop slug", required: true

    get("Shop Detail") do
      operationId "get"
      tags "Shops"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ShopMinimal"

        let(:stationSlug) { station.slug }
        let(:slug) { shop.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(404, "not found") do
        let(:stationSlug) { station.slug }
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end

      response(404, "not found") do
        let(:stationSlug) { "unknown-station" }
        let(:slug) { shop.slug }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
