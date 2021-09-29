# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/two_factors", type: :request, swagger_doc: "v1.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/users/two-factor/qrcode" do
    get("qrcode two_factor") do
      tags "Settings - TwoFactor"
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

  path "/users/two-factor/enable" do
    post("enable two_factor") do
      tags "Settings - TwoFactor"
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

  path "/users/two-factor/disable" do
    post("disable two_factor") do
      tags "Settings - TwoFactor"
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

  path "/users/two-factor/generate-backup-codes" do
    post("generate_backup_codes two_factor") do
      tags "Settings - TwoFactor"
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
