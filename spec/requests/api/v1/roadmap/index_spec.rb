# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/roadmap", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/roadmap" do
    get("Roadmap Items") do
      operationId "roadmapItems"
      tags "Roadmap"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/RoadmapItemQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/RoadmapItem"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/RoadmapItem"}

        let(:q) do
          {
            "nameCont" => "Galaxy"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first["name"]).to eq("Galaxy")
        end
      end
    end
  end
end
