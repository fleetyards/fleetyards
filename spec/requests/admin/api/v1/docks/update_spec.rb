# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/docks", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:docks]) }
  let(:dock) { create(:dock) }
  let(:id) { dock.id }
  let(:input) do
    {
      name: "Updated Pad"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/docks/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Dock") do
      operationId "updateDock"
      tags "Docks"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/DockInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Dock"

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
