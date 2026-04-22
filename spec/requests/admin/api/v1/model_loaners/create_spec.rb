# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_loaners", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_loaners]) }
  let(:model) { create(:model) }
  let(:loaner_model) { create(:model) }
  let(:request_body) do
    {
      modelId: model.id,
      loanerModelId: loaner_model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-loaners" do
    post("Create Model Loaner") do
      operationId "createModelLoaner"
      tags "ModelLoaners"

      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelLoanerInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaner"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { {modelId: "00000000-0000-0000-0000-000000000000"} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
