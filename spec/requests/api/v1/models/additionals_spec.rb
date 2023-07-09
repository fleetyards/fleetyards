# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/models/with-docks" do
    get("Models with Docks") do
      operationId "withDocks"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, type: :number, required: false, default: 1
      parameter name: "perPage", in: :query, type: :string, required: false,
        default: Model.default_per_page

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

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

          expect(items.count).to be > 0
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
        end
      end
    end
  end

  path "/models/unscheduled" do
    get("Unscheduled Models") do
      operationId "unschduled"
      tags "Models"
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

  path "/models/latest" do
    get("Latest Models") do
      operationId "latest"
      tags "Models"
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

  path "/models/slugs" do
    get("Available Model-Slugs") do
      operationId "slugs"
      tags "Models"
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

  path "/models/updated" do
    get("Updated Models") do
      operationId "updated"
      tags "Models"
      produces "application/json"

      parameter name: :from, in: :query, type: :string, format: :datetime, required: false
      parameter name: :to, in: :query, type: :string, format: :datetime, required: false, default: :now

      response(200, "successful") do
        let(:from) { 1.day.ago }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(304, "not modified") do
        run_test!
      end
    end
  end

  path "/models/embed" do
    get("Embed Models") do
      operationId "embed"
      tags "Models"
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
