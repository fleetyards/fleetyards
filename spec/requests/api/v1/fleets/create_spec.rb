# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:input) do
    {
      fid: "STARFLEET",
      name: "Starfleet"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets" do
    post("Create Fleet") do
      operationId "createFleet"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetCreateInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Starfleet")
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { nil }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
