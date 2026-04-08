# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/images", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:images]) }
  let(:images) { create_list(:image, 3) }
  let(:input) do
    {
      ids: images.pluck(:id),
      enabled: true
    }
  end

  before do
    sign_in user if user.present?
  end

  path "/images/bulk" do
    put("Bulk update images") do
      operationId "updateBulkImage"
      tags "Images"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ImageUpdateBulkInput"}, required: true

      response(200, "successful") do
        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

        run_test!
      end
    end
  end
end
