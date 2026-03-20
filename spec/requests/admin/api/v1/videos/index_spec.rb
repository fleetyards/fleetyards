# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/videos", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:videos]) }
  let(:model) { create(:model) }
  let(:videos) { create_list(:video, 3, model:) }

  before do
    sign_in user if user.present?

    videos
  end

  path "/videos" do
    get("Videos list") do
      operationId "videos"
      tags "Videos"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Video.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          "$ref": "#/components/schemas/VideoQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Videos"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Videos"

        let(:q) do
          {
            "modelIdEq" => model.id
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
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
