# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/manufacturers", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:manufacturers]) }

  before do
    sign_in user if user.present?

    create_list(:manufacturer, 3)
    create_list(:manufacturer, 3, :with_models)
  end

  path "/manufacturers" do
    get("Manufacturers list") do
      operationId "manufacturers"
      tags "Manufacturers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Manufacturer.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ManufacturerQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(6)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"

        let(:q) do
          {
            "withModels" => true
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(3)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(2)
        end
      end

      include_examples "admin_auth"
    end
  end
end
