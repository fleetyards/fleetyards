# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:model) { models :andromeda }

  path "/models/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Detail") do
      operationId "model"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema "$ref": "#/components/schemas/ModelExtended"

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
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/hardpoints" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Hardpoints") do
      operationId "modelHardpoints"
      tags "Models"
      produces "application/json"

      parameter name: "source", in: :query,
        schema: {"$ref": "#/components/schemas/HardpointSourceEnum"}, required: false

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/Hardpoint"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(model.hardpoints.size)
          expect(data.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/images" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Images") do
      operationId "modelImages"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Image.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Images"

        let(:slug) { model.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(model.images.count)
          expect(items.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/videos" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Videos") do
      operationId "modelVideos"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Video.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Videos"

        let(:slug) { model.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(model.videos.count)
          expect(items.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/variants" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Variants") do
      operationId "modelVariants"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        let(:slug) { model.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(model.variants.count)
          expect(items.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/loaners" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Loaners") do
      operationId "modelLoaners"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        let(:slug) { model.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(model.loaners.count)
          expect(items.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/snub-crafts" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Snubcrafts") do
      operationId "modelSnubCrafts"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Model"}

        let(:slug) { model.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(model.snub_crafts.count)
          expect(data.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/modules" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    let(:model) { models :galaxy }

    get("Model Modules") do
      operationId "modelModules"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModules"

        let(:slug) { model.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(model.modules.count)
          expect(items.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/module-packages" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    let(:model) { models :galaxy }

    get("Model Module Packages") do
      operationId "modelModulePackages"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackages"

        let(:slug) { model.slug }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(model.module_packages.count)
          expect(items.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/upgrades" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Upgrades") do
      operationId "modelUpgrades"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelUpgrade"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(model.upgrades.count)
          expect(data.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/paints" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Paints") do
      operationId "modelPaints"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelPaint"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(model.paints.count)
          expect(data.count).to be > 0
        end
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end

  path "/models/{slug}/store-image" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Storeimage") do
      operationId "modelStoreImage"
      deprecated true

      tags "Models"

      response(302, "successful") do
        let(:slug) { model.slug }

        run_test!
      end
    end
  end

  path "/models/{slug}/fleetchart-image" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Fleetchart Image") do
      operationId "modelFleetchartImage"
      deprecated true

      tags "Models"

      response(302, "successful") do
        let(:slug) { model.slug }

        run_test!
      end

      response(404, "not found") do
        produces "application/json"

        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
