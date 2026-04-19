# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_modules", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_modules]) }
  let(:model_modules) { create_list(:model_module, 3) }
  let(:input) do
    {
      ids: model_modules.pluck(:id),
      active: true
    }
  end

  before do
    sign_in user if user.present?
  end

  path "/model-modules/bulk" do
    put("Bulk update model modules") do
      operationId "updateBulkModelModule"
      tags "ModelModules"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelModuleUpdateBulkInput"}, required: true

      response(200, "successful") do
        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
