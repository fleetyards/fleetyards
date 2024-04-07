# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/images", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :admin_users, :models

  let(:user) { admin_users :jeanluc }
  let(:model) { models :andromeda }
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

  before do
    sign_in user if user.present?
  end

  path "/images" do
    post("Image create") do
      operationId "createImage"
      tags "Images"

      consumes "multipart/form-data"
      produces "application/json"

      parameter name: :"", in: :formData, schema: {"$ref": "#/components/schemas/ImageInputCreate"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Image"

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
