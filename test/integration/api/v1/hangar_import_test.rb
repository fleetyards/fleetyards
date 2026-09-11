# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarImportTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/import" do
    put("Import to your personal Hangar") do
      operationId "hangarImport"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::ImportInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::ImportSubmitResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(409, "conflict") do
        schema ::Shared::V1::Schemas::ValidationError
      end
    end
  end

  def upload_blob(fixture)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/#{fixture}")),
      filename: fixture
    )
  end

  test "PUT /hangar/import queues the import" do
    user = create(:user)
    sign_in user
    blob = upload_blob("hangar_import.json")

    assert_api_response :put, 200, body: {import: blob.signed_id}

    assert_equal 1, Imports::HangarImport.where(user_id: user.id).count
  end

  test "PUT /hangar/import records the target group" do
    user = create(:user)
    group = HangarGroup.create!(user_id: user.id, name: "RSI", color: "#ffffff")
    sign_in user
    blob = upload_blob("hangar_import.json")

    assert_api_response :put, 200, body: {import: blob.signed_id, hangarGroupId: group.id}

    assert_equal group.id, Imports::HangarImport.find_by(user_id: user.id).hangar_group_id
  end

  # The id arrives from the client, so an id belonging to somebody else must not
  # file this user's ships under a group they cannot see.
  test "PUT /hangar/import ignores a group owned by somebody else" do
    user = create(:user)
    other = HangarGroup.create!(user_id: create(:user).id, name: "Theirs", color: "#ffffff")
    sign_in user
    blob = upload_blob("hangar_import.json")

    assert_api_response :put, 200, body: {import: blob.signed_id, hangarGroupId: other.id}

    assert_nil Imports::HangarImport.find_by(user_id: user.id).hangar_group_id
  end

  test "PUT /hangar/import returns 409 while one is already running" do
    user = create(:user)
    sign_in user
    blob = upload_blob("hangar_import.json")

    assert_api_response :put, 200, body: {import: blob.signed_id}
    assert_api_response :put, 409, body: {import: upload_blob("hangar_import.json").signed_id}
  end

  # The 400 path saves the record before it reads the file, so a run that finds
  # nothing must not leave a `created` row behind the already-running guard.
  test "PUT /hangar/import leaves no blocking row after an empty import" do
    user = create(:user)
    sign_in user

    assert_api_response :put, 400, body: {import: upload_blob("empty_hangar_import.json").signed_id}

    assert_empty Imports::HangarImport.where(user_id: user.id)
    assert_api_response :put, 200, body: {import: upload_blob("hangar_import.json").signed_id}
  end

  test "PUT /hangar/import returns 400 for empty import" do
    user = create(:user)
    sign_in user
    blob = upload_blob("empty_hangar_import.json")

    assert_api_response :put, 400, body: {import: blob.signed_id}
  end

  test "PUT /hangar/import returns 401 when not signed in" do
    blob = upload_blob("hangar_import.json")

    assert_api_response :put, 401, body: {import: blob.signed_id}
  end

  test "PUT /hangar/import with OAuth bearer token" do
    user = create(:user)
    blob = upload_blob("hangar_import.json")

    assert_api_response :put, 200,
      headers: oauth_headers_for(user, scopes: ["hangar", "hangar:write"]),
      body: {import: blob.signed_id}
  end
end
