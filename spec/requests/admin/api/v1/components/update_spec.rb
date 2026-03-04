# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/components", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:components]) }
  let(:component) { create(:component) }
  let(:id) { component.id }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ComponentInput"}, required: true

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
