# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:import_blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/hangar_import.json")),
      filename: "hangar_import.json"
    )
  end
  let(:input) do
    {
      newImport: import_blob.signed_id
    }
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

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarImportResult"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:import_blob) do
          ActiveStorage::Blob.create_and_upload!(
            io: File.open(Rails.root.join("test/fixtures/files/empty_hangar_import.json")),
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
