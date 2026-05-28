# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/compare", type: :openapi, openapi_schema_name: :"v1/schema" do
  def create_model_with_slug(slug)
    model = create(:model)
    model.update_columns(slug: slug)
    model
  end

  let!(:carrack) { create_model_with_slug("anvil-carrack") }
  let!(:cutlass) { create_model_with_slug("drake-cutlass-black") }

  let(:request_body) { {models: [carrack.slug, cutlass.slug]} }

  path "/compare/share" do
    post("Create a short share URL for a comparison") do
      operationId "compareShare"
      tags "Compare"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/CompareShareInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CompareShare"

        before do
          allow(Rails.configuration.app).to receive(:short_domain).and_return("fltyrd.test")
        end

        it "returns short and long URLs and persists a CompareImage" do |_example|
          post "/api/v1/compare/share", params: request_body.to_json, headers: {"Content-Type" => "application/json"}

          expect(response).to have_http_status(:ok)
          data = JSON.parse(response.body)
          expect(data["shortUrl"]).to match(%r{://fltyrd\.test/c/[A-Za-z0-9]{8}\z})
          expect(data["longUrl"]).to include("/compare")
          expect(data["longUrl"]).to include("anvil-carrack")
          expect(data["longUrl"]).to include("drake-cutlass-black")

          record = CompareImage.find_by(share_key: "anvil-carrack,drake-cutlass-black")
          expect(record).to be_present
          expect(record.short_code).to match(/\A[A-Za-z0-9]{8}\z/)
        end

        it "returns the same short_url for the same comparison" do |_example|
          post "/api/v1/compare/share", params: request_body.to_json, headers: {"Content-Type" => "application/json"}
          first = JSON.parse(response.body)["shortUrl"]

          post "/api/v1/compare/share", params: {models: [cutlass.slug, carrack.slug]}.to_json, headers: {"Content-Type" => "application/json"}
          second = JSON.parse(response.body)["shortUrl"]

          expect(first).to eq(second)
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"

        context "with no models supplied" do
          let(:request_body) { {models: []} }

          run_test!
        end

        context "with too many models" do
          let(:request_body) do
            {models: (1..(CompareImage::MAX_SHARE_MODELS + 1)).map { |i| "extra-#{i}" }}
          end

          run_test!
        end

        context "with only unknown slugs" do
          let(:request_body) { {models: ["does-not-exist"]} }

          run_test!
        end
      end
    end
  end
end
