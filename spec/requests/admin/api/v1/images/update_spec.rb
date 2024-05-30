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

  path "/images/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Image update") do
      operationId "updateImage"
      tags "Images"

      consumes "application/json"
      produces "application/json"

      parameter name: :image, in: :body, schema: {"$ref": "#/components/schemas/ImageInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Image"

        let(:user) { admin_users :jeanluc }
        let(:id) { model_image.id }
        let(:image) do
          {
            galleryId: model.id,
            galleryType: "Model",
            caption: "Test Caption"
          }
        end

        after do |example|
          if response&.body.present?
            example.metadata[:response][:content] = {
              "application/json": {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
        end

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { model_image.id }
        let(:image) { nil }

        run_test!
      end

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { admin_users :jeanluc }
        let(:id) { "00000000-0000-0000-0000-000000000000" }
        let(:image) { nil }

        run_test!
      end
    end
  end
end
