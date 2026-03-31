# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_loaners", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_loaners]) }
  let(:model_loaner) { create(:model_loaner) }
  let(:id) { model_loaner.id }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelLoanerInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaner"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

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
