# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/images", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:images]) }
  let(:model_image) { create(:image) }
  let(:id) { model_image.id }

  before do
    sign_in user if user.present?
  end

  path "/images/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Image destroy") do
      operationId "destroyImage"
      tags "Images"

      response(204, "successful") do
        run_test!
      end

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
