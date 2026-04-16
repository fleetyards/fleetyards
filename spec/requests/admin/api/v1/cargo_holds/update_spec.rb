# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/cargo_holds", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:cargo_holds]) }
  let(:cargo_hold) { create(:cargo_hold) }
  let(:id) { cargo_hold.id }
  let(:input) do
    {
      offsetX: 2.5,
      offsetY: 1.0,
      offsetZ: 0.0
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/cargo-holds/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Cargo Hold") do
      operationId "updateCargoHold"
      tags "CargoHolds"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/CargoHoldInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminCargoHold"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["offsetX"]).to eq(2.5)
          expect(data["offsetY"]).to eq(1.0)
          expect(data["offsetZ"]).to eq(0.0)
        end
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
