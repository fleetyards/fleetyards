# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:import_blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("spec/fixtures/files/hangar_import.json")),
      filename: "hangar_import.json"
    )
  end
  let(:input) do
    {
      import: import_blob.signed_id
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/import" do
    put("Import to your personal Hangar") do
      operationId "hangarImport"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      parameter name: :input,
        in: :body,
        schema: {"$ref": "#/components/schemas/ImportInput"},
        required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarImportResult"

        run_test!
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:import_blob) do
          ActiveStorage::Blob.create_and_upload!(
            io: File.open(Rails.root.join("spec/fixtures/files/empty_hangar_import.json")),
            filename: "empty_hangar_import.json"
          )
        end

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { nil }

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
