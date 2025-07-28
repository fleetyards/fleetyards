# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:model) { create(:model, :with_module_packages) }
  let(:slug) { model.slug }

  path "/models/{slug}/module-packages" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Module Packages") do
      operationId "modelModulePackages"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackages"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(model.module_packages.count)
          expect(items.count).to be > 0
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-model" }

        run_test!
      end
    end
  end
end
