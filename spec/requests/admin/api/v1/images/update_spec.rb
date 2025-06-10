# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/images", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:images]) }
  let(:image) { create(:image) }
  let(:gallery) { create(:model) }
  let(:id) { image.id }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ImageInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Image"

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

        run_test!
      end

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end
    end
  end
end
