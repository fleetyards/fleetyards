# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/imports", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:imports]) }
  let(:imports) { create_list(:import, 10) }

  before do
    sign_in user if user.present?

    imports
  end

  path "/imports" do
    get("Imports list") do
      operationId "imports"
      description "Get a List of Imports"
      produces "application/json"
      tags "Imports"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Import.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ImportQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Imports"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to be > 0
        end
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/Imports"

        let(:q) do
          {
            "typeEq" => imports.first.type
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(Import.where(type: imports.first.type).count)
        end
      end

      response(200, "filter by requester", hidden: true) do
        schema "$ref": "#/components/schemas/Imports"

        let(:admin_user) { create(:admin_user) }
        let(:hangar_user) { create(:user) }
        let(:admin_import) { create(:import, :model_import, admin_user: admin_user) }
        let(:user_import) { create(:import, :hangar_sync, user: hangar_user) }
        let(:system_import) { create(:import, :model_import) }
        let(:imports) { [admin_import, user_import, system_import] }

        context "with admin user filter" do
          let(:q) { {"adminUserUsernameIn" => [admin_user.username]} }

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].pluck("id")).to contain_exactly(admin_import.id)
          end
        end

        context "with user filter" do
          let(:q) { {"userUsernameIn" => [hangar_user.username]} }

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].pluck("id")).to contain_exactly(user_import.id)
          end
        end

        context "with include system" do
          let(:q) { {"includeSystem" => "true"} }

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].pluck("id")).to contain_exactly(system_import.id)
          end
        end

        context "with combined requester filters (OR semantics)" do
          let(:q) do
            {
              "adminUserUsernameIn" => [admin_user.username],
              "includeSystem" => "true"
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)

            expect(data["items"].pluck("id")).to contain_exactly(
              admin_import.id, system_import.id
            )
          end
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
