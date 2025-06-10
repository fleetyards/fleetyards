# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/components", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:components]) }

  before do
    sign_in user if user.present?

    create_list(:component, 2)
    create(:component, name: "CF-227 Badger")
  end

  path "/components" do
    get("Components list") do
      operationId "components"
      tags "Components"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Component.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ComponentQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Components"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Components"

        let(:q) do
          {
            "nameCont" => "Badger"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first["name"]).to eq("CF-227 Badger")
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Components"

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

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
