# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:model) { models :andromeda }

  path "/models/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Detail") do
      operationId "get"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema "$ref": "#/components/schemas/ModelComplete"

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
      operationId "hardpoints"
      tags "Models"
      produces "application/json"

      parameter name: "source", in: :query,
        schema: {"$ref": "#/components/schemas/ModelHardpointSourceEnum"}, required: false

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelHardpoint"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(model.model_hardpoints.size)
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
      operationId "images"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false, default: Image.default_per_page

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ImageMinimal"}
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

          expect(data.count).to eq(model.images.count)
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

  path "/models/{slug}/videos" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Videos") do
      operationId "videos"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false, default: Video.default_per_page

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VideoMinimal"}
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

          expect(data.count).to eq(model.videos.count)
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

  path "/models/{slug}/variants" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Variants") do
      operationId "variants"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false, default: Model.default_per_page

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelMinimal"}
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

          expect(data.count).to eq(model.variants.count)
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

  path "/models/{slug}/loaners" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Loaners") do
      operationId "loaners"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false, default: Model.default_per_page

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelMinimal"}
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

          expect(data.count).to eq(model.loaners.count)
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

  path "/models/{slug}/snub-crafts" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Snubcrafts") do
      operationId "snubCrafts"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelMinimal"}
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
      operationId "modules"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false, default: ModelModule.default_per_page

      response(200, "successful") do
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
      operationId "modulePackages"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false, default: ModelModule.default_per_page

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

          expect(data.count).to eq(model.modules.count)
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

  path "/models/{slug}/upgrades" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Upgrades") do
      operationId "upgrades"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelUpgradeMinimal"}

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
      operationId "paints"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelPaintMinimal"}

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
      operationId "storeImage"
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
      operationId "fleetchartImage"
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
