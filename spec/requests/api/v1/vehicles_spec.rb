# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/vehicles" do
    get("list vehicles") do
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

    post("create vehicle") do
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

  path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "id", schema: {type: :string, format: :uuid}

    patch("update vehicle") do
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:id) { SecureRandom.uuid }

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

    put("update vehicle") do
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:id) { SecureRandom.uuid }

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

    delete("delete vehicle") do
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:id) { SecureRandom.uuid }

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

  path "/vehicles/bulk" do
    put("update_bulk vehicle") do
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

  path "/vehicles/destroy-bulk" do
    put("destroy_bulk vehicle") do
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

  path "/vehicles/check-serial" do
    post("check_serial vehicle") do
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
end
