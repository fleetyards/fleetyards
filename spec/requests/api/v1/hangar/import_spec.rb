# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/import" do
    put("Import to your personal Hangar") do
      operationId "hangarImport"
      tags "Hangar"
      consumes "multipart/form-data"
      produces "application/json"

      parameter name: :import, in: :formData, type: :string, format: :binary, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarImportResult"

        let(:user) { users :data }
        let(:import) do
          {
            import: Rack::Test::UploadedFile.new(File.new(Rails.root.join("test/fixtures/files/hangar_import.json")))
          }
        end

        run_test!
      end

      response(400, "successful") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :data }
        let(:import) do
          {
            import: Rack::Test::UploadedFile.new(File.new(Rails.root.join("test/fixtures/files/empty_hangar_import.json")))
          }
        end

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { users :data }
        let(:import) { nil }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:import) { nil }

        run_test!
      end
    end
  end
end
