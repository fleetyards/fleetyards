# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_modules", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_modules]) }
  let(:model_modules) { create_list(:model_module, 3) }

  before do
    sign_in user if user.present?

    model_modules
  end

  path "/model-modules" do
    get("Model Modules list") do
      operationId "listModelModules"
      tags "ModelModules"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelModuleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModules"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
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
