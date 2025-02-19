# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/models", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:user) { admin_users :jeanluc }
  let(:model) { models :andromeda }
  let(:id) { model.id }

  before do
    sign_in user if user.present?
  end

  path "/models/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Model id", required: true

    get("Model Detail") do
      operationId "model"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "unknown-id" }

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
