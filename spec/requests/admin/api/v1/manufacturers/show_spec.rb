# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/manufacturers", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:manufacturers]) }
  let(:manufacturer) { create(:manufacturer) }
  let(:id) { manufacturer.id }

  before do
    sign_in user if user.present?
  end

  path "/manufacturers/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Manufacturer id", required: true

    get("Manufacturer Detail") do
      operationId "manufacturer"
      tags "Manufacturers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturer"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "c1a705dd-21ad-46f6-ba3d-9dbf506f8033" }

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
