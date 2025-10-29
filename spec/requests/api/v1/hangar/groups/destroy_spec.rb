# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/groups", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:hangar_group) { create(:hangar_group, user: author) }
  let(:id) { hangar_group.id }

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/groups/{id}" do
    parameter name: "id", in: :path, description: "HangarGroup ID", schema: {type: :string, format: :uuid}, required: true

    delete("HangarGroup Destroy") do
      operationId "destroyHangarGroup"
      tags "HangarGroups"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarGroup"

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user) }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

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
