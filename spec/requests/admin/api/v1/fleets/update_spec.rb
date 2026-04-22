# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/fleets", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:fleets]) }
  let(:fleet) { create(:fleet) }
  let(:id) { fleet.id }
  let(:request_body) do
    {
      name: "Updated Fleet"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{id}" do
    parameter name: "id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    put("Update Fleet") do
      operationId "updateFleet"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/FleetInput"} } }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Updated Fleet")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
