# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/videos", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:videos]) }
  let(:video) { create(:video) }
  let(:id) { video.id }

  before do
    sign_in user if user.present?
  end

  path "/videos/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Video destroy") do
      operationId "destroyVideo"
      tags "Videos"

      response(204, "successful") do
        run_test!
      end

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

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
