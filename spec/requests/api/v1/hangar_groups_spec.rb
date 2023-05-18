# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar_groups", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/hangar-groups" do
    get("list hangar_groups") do
      tags "HangarGroups"
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

    post("create hangar_group") do
      tags "HangarGroups"
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

  path "/hangar-groups/{id}" do
    parameter name: "id", in: :path, description: "id", schema: {type: :string, format: :uuid}

    patch("update hangar_group") do
      tags "HangarGroups"
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

    put("update hangar_group") do
      tags "HangarGroups"
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

    delete("delete hangar_group") do
      tags "HangarGroups"
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

  path "/hangar-groups/sort" do
    put("sort hangar_group") do
      tags "HangarGroups"
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
