# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/fleets", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:fleets]) }
  let(:input) do
    {
      name: "Test Fleet",
      fid: "test-fleet"
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Test Fleet")
        end
      end

      include_examples "admin_auth"
    end
  end
end
