# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/hangar/groups", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:hangar_group) { create(:hangar_group, user: author) }
  let(:id) { hangar_group.id }

  let(:request_body) do
    {
      name: "Hangar Group One Test"
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/groups/{id}" do
    parameter name: "id", in: :path, description: "HangarGroup ID", schema: {type: :string, format: :uuid}, required: true

    put("HangarGroup Update") do
      operationId "updateHangarGroup"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/HangarGroupUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarGroup"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Hangar Group One Test")
        end
      end

      include_examples "oauth_auth"

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user) }

        run_test!
      end
    end
  end
end
