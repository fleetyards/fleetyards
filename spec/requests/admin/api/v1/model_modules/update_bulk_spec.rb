# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_modules", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_modules]) }
  let(:model_modules) { create_list(:model_module, 3) }
  let(:request_body) do
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

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelModuleUpdateBulkInput"}

      response(200, "successful") do
        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
