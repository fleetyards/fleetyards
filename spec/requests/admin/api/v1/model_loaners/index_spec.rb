# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_loaners", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_loaners]) }
  let(:model_loaners) { create_list(:model_loaner, 3) }

  before do
    sign_in user if user.present?

    model_loaners
  end

  path "/model-loaners" do
    get("Model Loaners list") do
      operationId "listModelLoaners"
      tags "ModelLoaners"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelLoanerQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaners"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      include_examples "admin_auth"
    end
  end
end
