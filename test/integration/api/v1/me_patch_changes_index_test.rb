# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MePatchChangesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/patch-changes" do
    get("What the current build changed about my ships") do
      operationId "myPatchChanges"
      tags "Me"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::MyPatchChanges
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "GET /me/patch-changes returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /me/patch-changes lists the reader's changed ships, most changed first" do
    gladius = create(:model, name: "Gladius")
    cutlass = create(:model, name: "Cutlass Black")
    prospector = create(:model, name: "Prospector")
    untouched = create(:model, name: "Aurora")
    someone_elses = create(:model, name: "Idris")

    create_list(:vehicle, 2, user: @user, model: gladius)
    create(:vehicle, user: @user, model: cutlass)
    create(:vehicle, user: @user, model: prospector, wanted: true)
    create(:vehicle, user: @user, model: untouched)
    create(:vehicle, user: create(:user), model: someone_elses)

    record(gladius, fields: %w[mass scm_speed shield_hp])
    record(cutlass, fields: %w[cargo])
    record(prospector, fields: %w[mass fuel])
    record(someone_elses, fields: %w[mass])

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["totalCount"]
      assert_equal %w[Gladius Prospector], parsed_body["items"].first(2).map { |item| item.dig("model", "name") }

      gladius_item = parsed_body["items"].first
      assert_equal 2, gladius_item["ownedCount"]
      assert_not gladius_item["wanted"]
      assert_equal 3, gladius_item["changeCount"]

      prospector_item = parsed_body["items"].second
      assert_equal 0, prospector_item["ownedCount"]
      assert prospector_item["wanted"]
    end
  end

  test "GET /me/patch-changes leaves out loaners and earlier builds" do
    loaner = create(:model)
    old_news = create(:model)
    create(:vehicle, user: @user, model: loaner, loaner: true)
    create(:vehicle, user: @user, model: old_news)
    record(loaner, fields: %w[mass])
    record(old_news, fields: %w[mass], to_version: "4.9.0")

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 0, parsed_body["totalCount"]
      assert_empty parsed_body["items"]
    end
  end

  private def record(model, fields:, to_version: ScData::Source.version)
    fields.each do |field|
      ModelBuildChange.create!(
        model:, field:, to_version:, old_value: 1, new_value: 2,
        recorded_at: 1.day.ago,
        environment: ScData::Source.environment, from_version: "4.9.0"
      )
    end
  end
end
