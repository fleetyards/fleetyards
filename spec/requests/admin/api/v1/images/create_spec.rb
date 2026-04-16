# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/images", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:images]) }
  let(:gallery) { create(:model) }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("spec/fixtures/files/test.png")),
      filename: "test.png"
    )
  end
  let(:input) do
    {
      file: blob.signed_id,
      galleryId: gallery.id,
      galleryType: gallery.class.name
    }
  end

  before do
    sign_in user if user.present?
  end

  path "/images" do
    post("Image create") do
      operationId "createImage"
      tags "Images"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ImageInputCreate"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Image"

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
