# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  before do
    host! "api.fleetyards.test"
  end

  let(:model) { models :andromeda }

  path "/models/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("model detail") do
      operationId "getModel"
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
    parameter name: "slug", in: :path, type: :string, description: "slug"
    parameter name: "source", in: :query,
      schema: {"$ref": "#/components/schemas/ModelHardpointSourceEnum"}, required: false

    get("model hardpoints") do
      operationId "getHardpoints"
      tags "Models"
      produces "application/json"

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
    parameter name: "slug", in: :path, type: :string, description: "slug"
    parameter name: "page", in: :query, type: :number, required: false, default: 1
    parameter name: "perPage", in: :query, type: :string, required: false, default: Image.default_per_page

    get("model images") do
      operationId "getImages"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ImageMinimal"}

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
    parameter name: "slug", in: :path, type: :string, description: "slug"
    parameter name: "page", in: :query, type: :number, required: false, default: 1
    parameter name: "perPage", in: :query, type: :string, required: false, default: Video.default_per_page

    get("model videos") do
      operationId "getVideos"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/VideoMinimal"}

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
    parameter name: "slug", in: :path, type: :string, description: "slug"
    parameter name: "page", in: :query, type: :number, required: false, default: 1
    parameter name: "perPage", in: :query, type: :string, required: false, default: Model.default_per_page

    get("model variants") do
      operationId "getVariants"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelMinimal"}

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
    parameter name: "slug", in: :path, type: :string, description: "slug"
    parameter name: "page", in: :query, type: :number, required: false, default: 1
    parameter name: "perPage", in: :query, type: :string, required: false, default: Model.default_per_page

    get("model loaners") do
      operationId "getLoaners"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelMinimal"}

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
    parameter name: "slug", in: :path, type: :string, description: "slug"
    parameter name: "page", in: :query, type: :number, required: false, default: 1
    parameter name: "perPage", in: :query, type: :string, required: false, default: Model.default_per_page

    get("model snub crafts") do
      operationId "getSnubCrafts"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelMinimal"}

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
    parameter name: "slug", in: :path, type: :string, description: "slug"

    let(:model) { models :galaxy }

    get("model modules") do
      operationId "getModules"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { model.slug }

        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelModuleMinimal"}

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
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("model upgrades") do
      operationId "getUpgrades"
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
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("model paints") do
      operationId "getPaints"
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
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("model store image") do
      operationId "getStoreImage"
      deprecated true

      tags "Models"

      response(302, "successful") do
        let(:slug) { model.slug }

        run_test!
      end
    end
  end

  path "/models/{slug}/fleetchart-image" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("model fleetchart image") do
      operationId "getFleetchartImage"
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
