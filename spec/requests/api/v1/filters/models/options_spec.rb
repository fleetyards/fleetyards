# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/filters/models", type: :openapi, openapi_schema_name: :"v1/schema" do
  let!(:models) { create_list(:model, 6, :with_store_image) }

  path "/filters/models/options" do
    get("Model Options") do
      operationId "modelOptions"
      tags "ModelsFilters"
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

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelOptions"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(6)
          expect(items.first.keys).to match_array(%w[id name slug media])
        end
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/ModelOptions"

        let(:q) do
          {
            "nameCont" => models.first.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first["name"]).to eq(models.first.name)
        end
      end
    end
  end
end
