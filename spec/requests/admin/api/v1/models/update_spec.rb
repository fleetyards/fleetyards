# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/models", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:models]) }
  let(:model) { create(:model) }
  let(:id) { model.id }
  let(:input) do
    {
      name: "Enterprise A"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/models/{id}" do
    parameter name: "id", in: :path, description: "Model id", schema: {type: :string, format: :uuid}

    put("Update Model") do
      operationId "updateModel"
      tags "Models"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelUpdateInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Enterprise A")
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
