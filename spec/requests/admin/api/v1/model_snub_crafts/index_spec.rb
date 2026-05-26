# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_snub_crafts", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_snub_crafts]) }
  let(:model_snub_crafts) { create_list(:model_snub_craft, 3) }

  before do
    sign_in user if user.present?

    model_snub_crafts
  end

  path "/model-snub-crafts" do
    get("Model Snub Crafts list") do
      operationId "listModelSnubCrafts"
      tags "ModelSnubCrafts"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelSnubCraftQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelSnubCrafts"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      include_examples "admin_auth"
    end
  end
end
