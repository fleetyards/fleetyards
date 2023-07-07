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
    get("list images") do
      description "Get a List of Images"
      produces "application/json"
      tags "Images"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/Image"}

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
          response = JSON.parse(response.body)

          expect(response.count).to be > 0
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end

    post("create image") do
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

    patch("update image") do
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

    put("update image") do
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

    delete("delete image") do
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
