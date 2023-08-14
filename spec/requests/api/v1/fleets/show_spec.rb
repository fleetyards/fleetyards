# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  path "/fleets/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Detail") do
      operationId "fleet"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet.slug }

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
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-model" }

        run_test!
      end
    end
  end
end
