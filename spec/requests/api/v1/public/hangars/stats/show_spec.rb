# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/hangars/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { users :data }

  path "/public/hangars/{username}/stats" do
    parameter name: "username", in: :path, type: :string, description: "username"

    get("Public Hangar Stats") do
      operationId "get"
      tags "PublicHangarStats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarStatsPublic"

        let(:username) { user.username }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { "non-existent-username" }

        run_test!
      end
    end
  end
end
