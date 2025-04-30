# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:embeded_models) { create_list(:model, 3) }
  let(:models) { embeded_models.map(&:slug) }

  path "/models/embed" do
    get("Embed Models") do
      operationId "modelsEmbed"
      tags "Models"
      produces "application/json"

      parameter name: :models, in: :query, schema: {type: :array, items: {type: :string}}, required: true

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/Model"}

        run_test!
      end
    end
  end
end
