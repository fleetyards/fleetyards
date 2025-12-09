# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/models", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:model) { create(:model, :with_videos) }
  let(:id) { model.id }

  path "/models/{id}/videos" do
    parameter name: "id", in: :path, type: :string, description: "Model id", required: true

    get("Model Videos") do
      operationId "modelVideos"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Video.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Videos"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(model.videos.count)
          expect(items.count).to be > 0
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-model" }

        run_test!
      end
    end
  end
end
