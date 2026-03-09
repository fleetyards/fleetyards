# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/features", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:features]) }

  before do
    sign_in user if user.present?
    Flipper.enable("TestFeature")
  end

  path "/features" do
    get("Features list") do
      operationId "adminFeatures"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Feature"}

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first["name"]).to be_present
        end
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
