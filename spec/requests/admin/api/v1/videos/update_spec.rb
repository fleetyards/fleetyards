# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/videos", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:videos]) }
  let(:video) { create(:video) }
  let(:id) { video.id }
  let(:input) do
    {
      url: "newVideoId123"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/videos/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Video") do
      operationId "updateVideo"
      tags "Videos"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/VideoInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Video"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
