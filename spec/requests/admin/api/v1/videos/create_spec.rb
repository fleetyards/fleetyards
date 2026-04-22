# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/videos", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:videos]) }
  let(:model) { create(:model) }
  let(:request_body) do
    {
      modelId: model.id,
      url: "dQw4w9WgXcQ",
      videoType: "youtube"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/videos" do
    post("Create new Video") do
      operationId "createVideo"
      tags "Videos"

      consumes "application/json"
      produces "application/json"

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/VideoInput"} } }

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Video"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { {url: nil} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
