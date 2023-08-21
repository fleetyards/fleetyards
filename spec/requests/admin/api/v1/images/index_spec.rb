# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/images", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :admin_users, :images, :models

  let(:user) { nil }
  let(:model_image) { images :model_image }
  let(:model) { models :andromeda }

  before do
    sign_in user if user.present?
  end

  path "/images" do
    get("Images list") do
      operationId "images"
      description "Get a List of Images"
      produces "application/json"
      tags "Images"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Image.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ImageQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Images"

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
        schema "$ref": "#/components/schemas/Images"

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
        schema "$ref": "#/components/schemas/Images"

        let(:user) { admin_users :jeanluc }
        let(:q) do
          {
            "galleryIdEq" => model.id
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(1)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
