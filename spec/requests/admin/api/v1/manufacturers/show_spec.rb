# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/manufacturers", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :manufacturers, :admin_users

  let(:user) { admin_users :jeanluc }
  let(:manufacturer) { manufacturers :rsi }
  let(:id) { model.id }

  before do
    sign_in user if user.present?
  end

  path "/manufacturers/{id}" do
    parameter name: "id", in: :path, type: :string, format: :uuid, description: "Manufacturer id", required: true

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
