# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_upgrades", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_upgrades]) }
  let(:model_upgrades) { create_list(:model_upgrade, 3) }

  before do
    sign_in user if user.present?

    model_upgrades
  end

  path "/model-upgrades" do
    get("Model Upgrades list") do
      operationId "listModelUpgrades"
      tags "ModelUpgrades"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelUpgrade.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelUpgradeQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrades"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/ModelUpgrades"

        let(:q) do
          {
            "nameCont" => model_upgrades.first.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
        end
      end

      include_examples "admin_auth"
    end
  end
end
