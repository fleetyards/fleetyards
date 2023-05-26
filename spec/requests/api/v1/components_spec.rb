# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/components", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :components

  before do
    host! "api.fleetyards.test"
  end

  path "/components" do
    get("list components") do
      description "Get a List of Components"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ComponentMinimal"}

        after do |example|
          if response&.body.present?
            example.metadata[:response][:content] = {
              "application/json": {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
        end

        run_test!
      end
    end
  end

  path "/components/class_filters" do
    get("class_filters component") do
      description "Get a List of all Component Classes"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FilterOption"}

        after do |example|
          if response&.body.present?
            example.metadata[:response][:content] = {
              "application/json": {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
        end

        run_test!
      end
    end
  end

  path "/components/item_type_filters" do
    get("item_type_filters component") do
      description "Get a List of all Component Item Types"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FilterOption"}

        after do |example|
          if response&.body.present?
            example.metadata[:response][:content] = {
              "application/json": {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
        end

        run_test!
      end
    end
  end
end
