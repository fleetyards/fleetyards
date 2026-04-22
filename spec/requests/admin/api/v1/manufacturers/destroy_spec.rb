# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/manufacturers", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:manufacturers]) }
  let(:manufacturer) { create(:manufacturer) }
  let(:id) { manufacturer.id }

  before do
    sign_in(user) if user.present?
  end

  path "/manufacturers/{id}" do
    parameter name: "id", in: :path, description: "Manufacturer id", schema: {type: :string, format: :uuid}

    delete("Destroy Manufacturer") do
      operationId "destroyManufacturer"
      tags "Manufacturers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturer"

        run_test!
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
