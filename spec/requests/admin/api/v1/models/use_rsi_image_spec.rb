# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/models", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:models]) }
  let(:model) do
    m = create(:model)
    m.rsi_store_image.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/test.png")),
      filename: "test.png",
      content_type: "image/png"
    )
    m
  end
  let(:id) { model.id }

  before do
    sign_in(user) if user.present?
  end

  path "/models/{id}/use-rsi-image" do
    parameter name: "id", in: :path, description: "Model id", schema: {type: :string, format: :uuid}

    put("Use RSI Image") do
      operationId "useRsiImage"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
