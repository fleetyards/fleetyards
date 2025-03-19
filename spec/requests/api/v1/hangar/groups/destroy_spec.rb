# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/groups", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :hangar_groups, :users

  let(:user) { nil }
  let(:hangar_group) { hangar_groups :hangargroupone }

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

        let(:id) { hangar_group.id }
        let(:user) { users :data }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }
        let(:user) { users :data }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { hangar_group.id }

        run_test!
      end
    end
  end
end
