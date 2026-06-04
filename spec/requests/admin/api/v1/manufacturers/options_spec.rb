# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/manufacturers", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:manufacturers]) }

  let!(:manufacturers) { create_list(:manufacturer, 6, :with_logo) }

  before do
    sign_in(user) if user.present?
  end

  path "/manufacturers/options" do
    get("Manufacturer Options") do
      operationId "manufacturerOptions"
      tags "Manufacturers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/ManufacturerQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ManufacturerOptions"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(6)
          expect(items.first.keys).to match_array(%w[id name slug logo])
        end
      end

      include_examples "admin_auth"
    end
  end
end
