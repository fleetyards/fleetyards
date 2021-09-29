# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_members", type: :request, swagger_doc: "v1.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/fleets/{slug}/members" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("list fleet_members") do
      tags "Fleets - Members"
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

  path "/fleets/{slug}/member-quick-stats" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("quick_stats fleet_member") do
      tags "Fleets - Members"
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
