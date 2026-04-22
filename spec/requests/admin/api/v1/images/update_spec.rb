# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/images", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:images]) }
  let(:image) { create(:image) }
  let(:gallery) { create(:model) }
  let(:id) { image.id }
  let(:request_body) do
    {
      galleryId: gallery.id,
      galleryType: gallery.class.name,
      caption: "Test Caption"
    }
  end

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

      request_body schema: {"$ref": "#/components/schemas/ImageInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Image"

        run_test!
      end

      include_examples "admin_auth"

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end
    end
  end
end
