# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::VideosTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/videos" do
    post("Create new Video") do
      operationId "createVideo"
      tags "Videos"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/VideoInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Video"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Videos list") do
      operationId "videos"
      tags "Videos"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Video.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/VideoQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Videos"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/videos/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Video destroy") do
      operationId "destroyVideo"
      tags "Videos"

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

    get("Get Video") do
      operationId "video"
      tags "Videos"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Video"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Update Video") do
      operationId "updateVideo"
      tags "Videos"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/VideoInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Video"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:videos])
  end

  # POST /videos
  test "POST /videos creates a video" do
    model = create(:model)
    sign_in @user

    body = {modelId: model.id, url: "dQw4w9WgXcQ", videoType: "youtube"}
    assert_api_response :post, 201, body: body
  end

  test "POST /videos returns 400 for invalid body" do
    sign_in @user

    assert_api_response :post, 400, body: {url: nil}
  end

  test "POST /videos returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {modelId: model.id, url: "x", videoType: "youtube"}
  end

  test "POST /videos returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {modelId: model.id, url: "x", videoType: "youtube"}
  end

  # GET /videos
  test "GET /videos lists videos" do
    create_list(:video, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /videos filters by modelIdEq query" do
    model = create(:model)
    create_list(:video, 3, model: model)
    create_list(:video, 2)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"modelIdEq" => model.id}} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /videos returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /videos returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /videos/:id
  test "DELETE /videos/:id destroys the video" do
    video = create(:video)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: video.id}
  end

  test "DELETE /videos/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /videos/:id returns 401 when not signed in" do
    video = create(:video)

    assert_api_response :delete, 401, path_params: {id: video.id}
  end

  test "DELETE /videos/:id returns 403 for admin without access" do
    video = create(:video)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: video.id}
  end

  # GET /videos/:id
  test "GET /videos/:id returns the video" do
    video = create(:video)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: video.id}
  end

  test "GET /videos/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /videos/:id returns 401 when not signed in" do
    video = create(:video)

    assert_api_response :get, 401, path_params: {id: video.id}
  end

  test "GET /videos/:id returns 403 for admin without access" do
    video = create(:video)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: video.id}
  end

  # PUT /videos/:id
  test "PUT /videos/:id updates the video" do
    video = create(:video)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: video.id}, body: {url: "newVideoId123"}
  end

  test "PUT /videos/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {url: "x"}
  end

  test "PUT /videos/:id returns 401 when not signed in" do
    video = create(:video)

    assert_api_response :put, 401, path_params: {id: video.id}, body: {url: "x"}
  end

  test "PUT /videos/:id returns 403 for admin without access" do
    video = create(:video)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: video.id}, body: {url: "x"}
  end
end
