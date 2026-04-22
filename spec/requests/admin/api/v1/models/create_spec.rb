# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/models", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:models]) }
  let(:manufacturer) { create(:manufacturer) }
  let(:input) do
    {
      name: "Enterprise",
      manufacturerId: manufacturer.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/models" do
    post("Create Model") do
      operationId "createModel"
      tags "Models"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelCreateInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Enterprise")
        end
      end

      include_examples "admin_auth"
    end
  end
end
