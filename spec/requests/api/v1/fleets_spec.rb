# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/fleets" do
    post("create fleet") do
      tags "Fleets"
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

  path "/fleets/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("show fleet") do
      tags "Fleets"
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

    patch("update fleet") do
      tags "Fleets"
      consumes "application/json"
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

    put("update fleet") do
      tags "Fleets"
      consumes "application/json"
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

    delete("delete fleet") do
      tags "Fleets"
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

  path "/fleets/check" do
    post("check fleet") do
      tags "Fleets"
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

  path "/fleets/invites" do
    get("invites fleet") do
      tags "Fleets"
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

  path "/fleets/current" do
    get("current fleet") do
      tags "Fleets"
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
