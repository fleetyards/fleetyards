# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/models", type: :request, swagger_doc: "admin/v1/schema.yaml" do
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
