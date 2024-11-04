# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/imports", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:user) { admin_users :jeanluc }

  before do
    sign_in user if user.present?
  end

  path "/imports" do
    get("Imports list") do
      operationId "imports"
      description "Get a List of Imports"
      produces "application/json"
      tags "Imports"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Import.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ImportQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Imports"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to be > 0
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Imports"

        let(:q) do
          {
            "typeEq" => "::Imports::ModelImport"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
