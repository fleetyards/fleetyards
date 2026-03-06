# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_loaners", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_loaners]) }
  let(:model) { create(:model) }
  let(:loaner_model) { create(:model) }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelLoanerInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaner"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { {modelId: "00000000-0000-0000-0000-000000000000"} }

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
