# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/fleets/{slug}/vehicles" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("list fleet_vehicles") do
      tags "Fleets - Vehicles"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/public-vehicles" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("public fleet_vehicle") do
      tags "Fleets - Vehicles"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/fleetchart" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("fleetchart fleet_vehicle") do
      tags "Fleets - Vehicles"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/public-fleetchart" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("public_fleetchart fleet_vehicle") do
      tags "Fleets - Vehicles"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/quick-stats" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("quick_stats fleet_vehicle") do
      tags "Fleets - Vehicles"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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
