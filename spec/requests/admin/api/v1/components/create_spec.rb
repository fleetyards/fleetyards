# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/components", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:components]) }
  let(:request_body) do
    {
      name: "Power Plant"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/components" do
    post("Create Component") do
      operationId "createComponent"
      tags "Components"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ComponentInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Component"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Power Plant")
        end
      end

      include_examples "admin_auth"
    end
  end
end
