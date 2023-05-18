# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_memberships", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/fleets/use-invite" do
    post("create_by_invite fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
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

  path "/fleets/{slug}/members/current" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"

    get("current fleet_membership") do
      tags "Fleets - Memberships"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/members" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"

    put("update fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

    patch("update fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

    post("create fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/members/accept-invite" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"

    put("accept_invite fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/members/decline-invite" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"

    put("decline_invite fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/members/leave" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"

    delete("leave fleet_membership") do
      tags "Fleets - Memberships"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/members/create-by-invite" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"

    post("create_by_invite fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }

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

  path "/fleets/{slug}/members/{username}/demote" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "username"

    put("demote fleet_membership") do
      tags "Fleets - Memberships"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }
        let(:username) { "123" }

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

  path "/fleets/{slug}/members/{username}/promote" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "username"

    put("promote fleet_membership") do
      tags "Fleets - Memberships"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }
        let(:username) { "123" }

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

  path "/fleets/{slug}/members/{username}/accept-request" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "username"

    put("accept_request fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }
        let(:username) { "123" }

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

  path "/fleets/{slug}/members/{username}/decline-request" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "username"

    put("decline_request fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }
        let(:username) { "123" }

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

  path "/fleets/{slug}/members/{username}" do
    parameter name: "slug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "username"

    delete("delete fleet_membership") do
      tags "Fleets - Memberships"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:slug) { "123" }
        let(:username) { "123" }

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
