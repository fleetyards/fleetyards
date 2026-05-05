# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/filters/models", type: :request, swagger_doc: "v1/schema.yaml" do
  let!(:models) { create_list(:model, 2) }

  path "/filters/models/focus" do
    get("Model focus Filters") do
      operationId "modelFocusFilters"
      tags "ModelsFilters"
      produces "application/json"

      parameter name: :classification, in: :query, type: :string, required: false,
        description: "Restrict the result to focuses of models with this classification"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
      end

      response(200, "successful with classification filter") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}

        let(:classification) { "combat" }

        before do
          create(:model, classification: "combat", focus: "Heavy Fighter")
          create(:model, classification: "industrial", focus: "Mining")
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.map { |row| row["value"] }).not_to include("Mining")
        end
      end
    end
  end
end
