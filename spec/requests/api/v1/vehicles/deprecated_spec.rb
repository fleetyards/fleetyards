# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/vehicles" do
    get("list vehicles") do
      deprecated true
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/fleetchart" do
    get("fleetchart vehicle") do
      operationId "fleetchart"
      deprecated true
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/export" do
    get("export vehicle") do
      operationId "export"
      deprecated true
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/import" do
    put("import vehicle") do
      operationId "import"
      deprecated true
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/destroy-all" do
    delete("destroy_all vehicle") do
      operationId "destroyAll"
      deprecated true
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/embed" do
    get("embed vehicle") do
      operationId "embed"
      deprecated true
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/hangar-items" do
    get("hangar_items vehicle") do
      operationId "hangarItems"
      deprecated true
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/hangar" do
    get("hangar vehicle") do
      operationId "hangar"
      deprecated true
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/quick-stats" do
    get("quick_stats vehicle") do
      operationId "quickStats"
      deprecated true
      tags "Vehicles - Stats"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/stats/models-by-size" do
    get("models_by_size vehicle") do
      operationId "statsModelsBySize"
      deprecated true
      tags "Vehicles - Stats"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/stats/models-by-production-status" do
    get("models_by_production_status vehicle") do
      operationId "statsModelsByProductionStatus"
      deprecated true
      tags "Vehicles - Stats"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/stats/models-by-manufacturer" do
    get("models_by_manufacturer vehicle") do
      operationId "statsModelsByManufacturer"
      deprecated true
      tags "Vehicles - Stats"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/stats/models-by-classification" do
    get("models_by_classification vehicle") do
      operationId "statsModelsByClassification"
      deprecated true
      tags "Vehicles - Stats"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/{username}" do
    parameter name: "username", in: :path, type: :string, description: "username"

    get("public vehicle") do
      operationId "public"
      deprecated true
      tags "Vehicles - Public"
      produces "application/json"

      response(200, "successful") do
        let(:username) { "123" }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/{username}/fleetchart" do
    parameter name: "username", in: :path, type: :string, description: "username"

    get("public_fleetchart vehicle") do
      operationId "publicFleetchart"
      deprecated true
      tags "Vehicles - Public"
      produces "application/json"

      response(200, "successful") do
        let(:username) { "123" }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/vehicles/{username}/quick-stats" do
    parameter name: "username", in: :path, type: :string, description: "username"

    get("public_quick_stats vehicle") do
      operationId "publicQuickStats"
      deprecated true
      tags "Vehicles - Public"
      produces "application/json"

      response(200, "successful") do
        let(:username) { "123" }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end
end
