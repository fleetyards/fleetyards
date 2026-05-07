# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_paints", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_paints]) }
  let(:model_paints) { create_list(:model_paint, 3) }

  before do
    sign_in user if user.present?

    model_paints
  end

  path "/model-paints" do
    get("Paints list") do
      operationId "listModelPaints"
      tags "ModelPaints"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelPaint.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelPaintQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaints"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/ModelPaints"

        let(:q) do
          {
            "nameCont" => model_paints.first.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
        end
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/ModelPaints"

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(2)
          expect(data.dig("meta", "pagination", "totalPages")).to eq(2)
        end
      end

      include_examples "admin_auth"
    end
  end
end
