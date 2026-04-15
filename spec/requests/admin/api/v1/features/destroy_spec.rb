# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/features", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:features]) }
  let(:id) { "TestFeature" }

  before do
    sign_in user if user.present?
    Flipper.add("TestFeature")
  end

  path "/features/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    delete("Delete Feature") do
      operationId "destroyAdminFeature"
      tags "Features"

      response(204, "deleted") do
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:id) { "NonExistentFeature" }
        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
