# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/models", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  before do
    sign_in user if user.present?
  end

  path "/models" do
    get("Models list") do
      operationId "models"
      description "Get a List of Models"
      produces "application/json"
      tags "Models"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        let(:user) { admin_users :jeanluc }

        after do |example|
          if response&.body.present?
            example.metadata[:response][:content] = {
              "application/json": {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to be > 0
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        let(:user) { admin_users :jeanluc }
        let(:q) do
          {
            "nameCont" => "Andromeda"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"

        let(:user) { admin_users :jeanluc }
        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(2)
          expect(data.dig("meta", "pagination", "totalPages")).to eq(7)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
