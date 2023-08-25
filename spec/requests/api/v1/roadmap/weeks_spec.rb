# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/roadmap", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  before do
    travel_to 2.weeks.ago.end_of_week(:thursday)
  end

  after do |example|
    travel_back
  end

  path "/roadmap/weeks" do
    get("Roadmap Weeks") do
      operationId "roadmapWeeks"
      tags "Roadmap"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/RoadmapWeek"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
      end
    end
  end
end
