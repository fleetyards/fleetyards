# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:embeded_models) { create_list(:model, 3) }

  path "/models/embed" do
    get("Embed Models") do
      operationId "modelsEmbed"
      tags "Models"
      produces "application/json"

      parameter name: :models, in: :query, schema: {type: :array, items: {type: :string}}, style: :form, explode: true, required: true

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/Model"}

        it "returns embedded models" do |example|
          slugs = embeded_models.map(&:slug)
          query = slugs.map { |s| "models[]=#{s}" }.join("&")
          get "/api/v1/models/embed?#{query}"

          expect(response).to have_http_status(:ok)
          data = JSON.parse(response.body)
          expect(data.count).to eq(3)

          example.metadata[:response] = {code: response.status.to_s}
        end
      end
    end
  end
end
