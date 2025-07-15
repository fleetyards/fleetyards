# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  let!(:models) { create_list(:model, 6) }

  path "/models" do
    get("Models List") do
      operationId "models"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(6)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        let(:q) do
          {
            "nameOrDescriptionCont" => models.first.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first["name"]).to eq(models.first.name)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(2)
        end
      end
    end
  end
end
