# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/models/with-docks" do
    get("Models with Docks") do
      operationId "modelsWithDocks"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false

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

  path "/models/unscheduled" do
    get("Unscheduled Models") do
      operationId "modelsUnschduled"
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
      operationId "modelsLatest"
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
      operationId "modelsSlugs"
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
      operationId "modelsUpdated"
      tags "Models"
      produces "application/json"

      parameter name: :from, in: :query, schema: {type: :string, format: :datetime}, required: false
      parameter name: :to, in: :query, schema: {type: :string, default: :now, format: :datetime}, required: false

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
