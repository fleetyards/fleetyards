# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/docks", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:docks]) }
  let(:model) { create(:model) }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/DockInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Dock"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { {name: "Missing required fields"} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
