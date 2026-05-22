# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/manufacturers", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:manufacturers]) }
  let(:request_body) do
    {
      name: "Roberts Space Industries"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/manufacturers" do
    post("Create Manufacturer") do
      operationId "createManufacturer"
      tags "Manufacturers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ManufacturerInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturer"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Roberts Space Industries")
        end
      end

      include_examples "admin_auth"
    end
  end
end
