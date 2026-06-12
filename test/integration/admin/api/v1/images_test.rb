# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ImagesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, update_bulk, update).

  api_path "/images" do
    post("Image create") do
      operationId "createImage"
      tags "Images"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/ImageInputCreate"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Image"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

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
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/images/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Image destroy") do
      operationId "destroyImage"
      tags "Images"

      response(204, "successful")

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Image update") do
      operationId "updateImage"
      tags "Images"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/ImageInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Image"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/images/bulk" do
    put("Bulk update images") do
      operationId "updateBulkImage"
      tags "Images"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ImageUpdateBulkInput"}

      response(200, "successful")

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:images])
  end

  def upload_blob
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("spec/fixtures/files/test.png")),
      filename: "test.png"
    )
  end

  # POST /images
  test "POST /images uploads an image to a gallery" do
    gallery = create(:model)
    sign_in @user

    body = {file: upload_blob.signed_id, galleryId: gallery.id, galleryType: gallery.class.name}
    assert_api_response :post, 200, body: body
  end

  test "POST /images returns 401 when not signed in" do
    gallery = create(:model)

    body = {file: upload_blob.signed_id, galleryId: gallery.id, galleryType: gallery.class.name}
    assert_api_response :post, 401, body: body
  end

  test "POST /images returns 403 for admin without access" do
    gallery = create(:model)
    sign_in create(:admin_user, resource_access: [])

    body = {file: upload_blob.signed_id, galleryId: gallery.id, galleryType: gallery.class.name}
    assert_api_response :post, 403, body: body
  end

  # GET /images
  test "GET /images lists images" do
    create_list(:image, 2)
    create_list(:image, 2, gallery: create(:model))
    sign_in @user

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /images filters by galleryIdEq query" do
    create_list(:image, 2)
    model = create(:model)
    create_list(:image, 2, gallery: model)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"galleryIdEq" => model.id}} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /images returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /images returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /images/:id
  test "DELETE /images/:id destroys the image" do
    image = create(:image)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: image.id}
  end

  test "DELETE /images/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /images/:id returns 401 when not signed in" do
    image = create(:image)

    assert_api_response :delete, 401, path_params: {id: image.id}
  end

  test "DELETE /images/:id returns 403 for admin without access" do
    image = create(:image)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: image.id}
  end

  # PUT /images/:id
  test "PUT /images/:id updates the image" do
    image = create(:image)
    gallery = create(:model)
    sign_in @user

    body = {galleryId: gallery.id, galleryType: gallery.class.name, caption: "Test Caption"}
    assert_api_response :put, 200, path_params: {id: image.id}, body: body
  end

  test "PUT /images/:id returns 404 for missing id" do
    gallery = create(:model)
    sign_in @user

    body = {galleryId: gallery.id, galleryType: gallery.class.name, caption: "x"}
    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: body
  end

  test "PUT /images/:id returns 401 when not signed in" do
    image = create(:image)
    gallery = create(:model)

    body = {galleryId: gallery.id, galleryType: gallery.class.name, caption: "x"}
    assert_api_response :put, 401, path_params: {id: image.id}, body: body
  end

  test "PUT /images/:id returns 403 for admin without access" do
    image = create(:image)
    gallery = create(:model)
    sign_in create(:admin_user, resource_access: [])

    body = {galleryId: gallery.id, galleryType: gallery.class.name, caption: "x"}
    assert_api_response :put, 403, path_params: {id: image.id}, body: body
  end

  # PUT /images/bulk
  test "PUT /images/bulk updates multiple images" do
    images = create_list(:image, 3)
    sign_in @user

    assert_api_response :put, 200, body: {ids: images.pluck(:id), enabled: true}
  end

  test "PUT /images/bulk returns 401 when not signed in" do
    images = create_list(:image, 3)

    assert_api_response :put, 401, body: {ids: images.pluck(:id), enabled: true}
  end

  test "PUT /images/bulk returns 403 for admin without access" do
    images = create_list(:image, 3)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, body: {ids: images.pluck(:id), enabled: true}
  end
end
