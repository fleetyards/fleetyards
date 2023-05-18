# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/shops", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/shops" do
    get("list shops") do
      tags "Shops"
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

  path "/stations/{station_slug}/shops/{slug}" do
    parameter name: "station_slug", in: :path, type: :string, description: "station_slug"
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("show shop") do
      tags "Shops"
      produces "application/json"

      response(200, "successful") do
        let(:station_slug) { "123" }
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

  path "/shops/shop-types" do
    get("shop_types shop") do
      tags "Shops"
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
