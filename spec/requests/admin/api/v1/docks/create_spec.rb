# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/docks", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:docks]) }
  let(:model) { create(:model) }
  let(:request_body) do
    {
      name: "Pad 01",
      dockType: "landingpad",
      shipSize: "medium",
      modelId: model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/docks" do
    post("Create new Dock") do
      operationId "createDock"
      tags "Docks"

      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/DockInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Dock"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { {name: "Missing required fields"} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
