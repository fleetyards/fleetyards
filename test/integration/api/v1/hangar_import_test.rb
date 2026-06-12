# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::HangarImportTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/import" do
    put("Import to your personal Hangar") do
      operationId "hangarImport"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ImportInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarImportResult"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end
    end
  end

  def upload_blob(fixture)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("spec/fixtures/files/#{fixture}")),
      filename: fixture
    )
  end

  test "PUT /hangar/import imports the hangar fixture" do
    user = create(:user)
    sign_in user
    blob = upload_blob("hangar_import.json")

    assert_api_response :put, 200, body: {import: blob.signed_id}
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
