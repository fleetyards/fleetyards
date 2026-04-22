# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/images", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:images]) }
  let(:images) { create_list(:image, 3) }
  let(:request_body) do
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

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/ImageUpdateBulkInput"} } }

      response(200, "successful") do
        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
