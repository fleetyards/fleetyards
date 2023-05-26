# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_invite_urls", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/fleets/{slug}/invite-urls" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"

    get("list fleet_invite_urls") do
      tags "Fleets - Invite Urls"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json": {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end

    post("create fleet_invite_url") do
      tags "Fleets - Invite Urls"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json": {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end

  path "/fleets/{slug}/invite-urls/{token}" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "token", in: :path, type: :string, description: "token"

    delete("delete fleet_invite_url") do
      tags "Fleets - Invite Urls"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }
        let(:token) { "123" }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end
end
