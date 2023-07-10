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
      operationId "list"
      description "Get a List of Images"
      produces "application/json"
      tags "Images"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false,
        default: Image.default_per_page
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

    post("Image create") do
      operationId "create"
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

  path "/images/{id}" do
    parameter name: "id", in: :path, type: :string, format: :uuid, description: "id"

    put("Image update") do
      consumes "application/json"
      produces "application/json"
      tags "Images"

      parameter name: :image, in: :body, schema: {
        type: :object,
        properties: {"$ref": "#/components/schemas/ImageInput"}
      }

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

    delete("Image destroy") do
      operationId "destroy"
      tags "Images"

      response(200, "successful") do
        let(:user) { admin_users :jeanluc }
        let(:id) { model_image.id }

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

        run_test!
      end

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { admin_users :jeanluc }
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end
    end
  end
end
