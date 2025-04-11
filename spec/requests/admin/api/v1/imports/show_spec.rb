# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/imports", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:imports]) }
  let(:import) { create(:import) }
  let(:id) { import.id }

  before do
    sign_in user if user.present?
  end

  path "/imports/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id", required: true

    get("Import Detail") do
      operationId "import"
      tags "Imports"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Import"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "unknown-id" }

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
