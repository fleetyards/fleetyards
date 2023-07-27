# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/commodities", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  before do
    sign_in user if user.present?
  end

  path "/commodities" do
    get("Commodities list") do
      operationId "commodities"
      description "Get a List of Commodities"
      produces "application/json"
      tags "Commotities"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/CommodityQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Commodities"

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
        schema "$ref": "#/components/schemas/Commodities"

        let(:user) { admin_users :jeanluc }
        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
          expect(data.dig("meta", "pagination", "totalPages")).to eq(2)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
