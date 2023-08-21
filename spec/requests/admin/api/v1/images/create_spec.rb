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
    post("Image create") do
      operationId "createImage"
      description "Create a new Image"
      consumes "multipart/form-data"
      produces "application/json"
      tags "Images"

      parameter name: :"", in: :formData, schema: {"$ref": "#/components/schemas/ImageInputCreate"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Image"

        let(:user) { admin_users :jeanluc }
        let(:"") do
          {
            file: ActionDispatch::Http::UploadedFile.new(
              filename: "img.png",
              type: "image/png",
              tempfile: File.new(Rails.root.join("test/fixtures/files/test.png"))
            ),
            galleryId: model.id,
            galleryType: "Model"
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

        let(:"") { nil }

        run_test!
      end
    end
  end
end
