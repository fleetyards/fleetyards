# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/videos", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:videos]) }
  let(:model) { create(:model) }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/VideoInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Video"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { {url: nil} }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

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
