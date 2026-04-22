# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/components", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:components]) }
  let(:component) { create(:component) }
  let(:id) { component.id }
  let(:request_body) do
    {
      name: "Updated Component"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/components/{id}" do
    parameter name: "id", in: :path, description: "Component id", schema: {type: :string, format: :uuid}

    put("Update Component") do
      operationId "updateComponent"
      tags "Components"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ComponentInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Component"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Updated Component")
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
