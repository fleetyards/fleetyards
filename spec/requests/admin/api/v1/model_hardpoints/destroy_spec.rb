# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_hardpoints", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_hardpoints]) }
  let(:model_hardpoint) { create(:model_hardpoint) }
  let(:id) { model_hardpoint.id }

  before do
    sign_in user if user.present?
  end

  path "/model-hardpoints/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Destroy Model Hardpoint") do
      operationId "destroyModelHardpoint"
      tags "ModelHardpoints"

      response(204, "successful") do
        run_test!
      end

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
