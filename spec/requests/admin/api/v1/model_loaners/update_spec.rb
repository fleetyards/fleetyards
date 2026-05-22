# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_loaners", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_loaners]) }
  let(:model_loaner) { create(:model_loaner) }
  let(:id) { model_loaner.id }
  let(:request_body) do
    {
      hidden: true
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-loaners/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Model Loaner") do
      operationId "updateModelLoaner"
      tags "ModelLoaners"

      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelLoanerInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaner"

        run_test!
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
