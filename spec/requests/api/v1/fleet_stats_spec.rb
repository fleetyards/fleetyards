# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_stats", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/fleets/{slug}/stats/models-by-size" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("models_by_size fleet_stat") do
      tags "Fleets - Stats"
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

  path "/fleets/{slug}/stats/models-by-production-status" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("models_by_production_status fleet_stat") do
      tags "Fleets - Stats"
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

  path "/fleets/{slug}/stats/models-by-manufacturer" do
    before do
      host! "api.fleetyards.test"
    end

    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("models_by_manufacturer fleet_stat") do
      tags "Fleets - Stats"
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

  path "/fleets/{slug}/stats/models-by-classification" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("models_by_classification fleet_stat") do
      tags "Fleets - Stats"
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
