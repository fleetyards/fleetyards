# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/images", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:images]) }
  let(:model) { create(:model) }

  before do
    sign_in user if user.present?

    create_list(:image, 2)
    create_list(:image, 2, gallery: model)
  end

  path "/images" do
    get("Images list") do
      operationId "images"
      description "Get a List of Images"
      produces "application/json"
      tags "Images"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Image.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ImageQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Images"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to be > 0
        end
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/Images"

        let(:q) do
          {
            "galleryIdEq" => model.id
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(2)
        end
      end

      include_examples "admin_auth"
    end
  end
end
