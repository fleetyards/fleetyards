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

        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
