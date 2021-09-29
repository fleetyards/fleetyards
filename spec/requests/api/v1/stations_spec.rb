# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/stations", type: :request, swagger_doc: "v1.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/stations" do
    get("list stations") do
      tags "Stations"
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

  path "/stations/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("show station") do
      tags "Stations"
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

  path "/stations/{slug}/images" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("images station") do
      tags "Stations"
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

  path "/stations/ship-sizes" do
    get("ship_sizes station") do
      tags "Stations"
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

  path "/stations/station-types" do
    get("station_types station") do
      tags "Stations"
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

  path "/stations/classifications" do
    get("classifications station") do
      tags "Stations"
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
