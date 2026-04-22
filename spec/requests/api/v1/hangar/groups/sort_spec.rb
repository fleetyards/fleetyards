# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/hangar/groups", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:hangar_groups) { create_list(:hangar_group, 3, user: author) }

  let(:request_body) do
    {
      sorting: hangar_groups.reverse.map(&:id)
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

    hangar_groups
  end

  path "/hangar/groups/sort" do
    put("HangarGroup sort") do
      operationId "hangarGroupSort"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/HangarGroupSortInput"} } }

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema type: :object, properties: {success: {type: :boolean}}

        run_test! do
          hangar_groups.reverse.each_with_index do |group, index|
            expect(group.reload.sort).to eq(index)
          end
        end
      end

      include_examples "oauth_auth"
    end
  end
end
