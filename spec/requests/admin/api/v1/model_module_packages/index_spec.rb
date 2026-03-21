# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_module_packages", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_module_packages]) }
  let(:model_module_packages) { create_list(:model_module_package, 3) }

  before do
    sign_in user if user.present?

    model_module_packages
  end

  path "/model-module-packages" do
    get("Model Module Packages list") do
      operationId "listModelModulePackages"
      tags "ModelModulePackages"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModulePackage.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelModulePackageQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackages"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackages"

        let(:q) do
          {
            "nameCont" => model_module_packages.first.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
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
