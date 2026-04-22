# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/manufacturers", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:manufacturers]) }
  let(:manufacturer) { create(:manufacturer) }
  let(:id) { manufacturer.id }
  let(:request_body) do
    {
      name: "Updated Manufacturer"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/manufacturers/{id}" do
    parameter name: "id", in: :path, description: "Manufacturer id", schema: {type: :string, format: :uuid}

    put("Update Manufacturer") do
      operationId "updateManufacturer"
      tags "Manufacturers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ManufacturerInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturer"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Updated Manufacturer")
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
