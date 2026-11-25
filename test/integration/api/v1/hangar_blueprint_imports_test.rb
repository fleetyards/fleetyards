# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarBlueprintImportsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  MATCH_PATH = "/hangar/blueprint-imports/match"
  IMPORT_PATH = "/hangar/blueprint-imports"

  api_path MATCH_PATH do
    put("Match blueprint names from the game logs") do
      operationId "matchBlueprintLogNames"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::BlueprintLogMatchInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::BlueprintLogMatchList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path IMPORT_PATH do
    put("Import blueprints from the game logs") do
      operationId "importBlueprintsFromLogs"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::BlueprintLogImportInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::BlueprintLogImportResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    @akura = create(:blueprint, name: "5CA 'Akura'")
    @rifle = create(:blueprint, name: "Custodian \"Desert Shadow\" SMG")
    @helmet_a = create(:blueprint, name: "Argus Helmet Black/Silver")
    @helmet_b = create(:blueprint, name: "Argus Helmet Black/Silver")
  end

  test "PUT match resolves each name, ignoring case, quote style and spacing" do
    create(:user_blueprint, user: @user, blueprint: @rifle)
    sign_in @user

    assert_api_response :put, 200, api_path: MATCH_PATH,
      body: {names: ["5ca ‘Akura’", "Custodian  \"Desert Shadow\" SMG", "Nothing Like It"]} do
      assert_equal ["5ca ‘Akura’", "Custodian  \"Desert Shadow\" SMG", "Nothing Like It"], parsed_body.pluck("name")

      akura, rifle, unknown = parsed_body.pluck("blueprints")

      assert_equal [{"slug" => @akura.slug, "name" => "5CA 'Akura'", "owned" => false, "wanted" => false}], akura
      assert_equal [true], rifle.pluck("owned")
      assert_empty unknown
    end
  end

  test "PUT match offers every blueprint a shared name can mean" do
    sign_in @user

    assert_api_response :put, 200, api_path: MATCH_PATH, body: {names: ["Argus Helmet Black/Silver"]} do
      assert_equal [@helmet_a.slug, @helmet_b.slug].sort, parsed_body.first["blueprints"].pluck("slug").sort
    end
  end

  test "PUT match lists a name once however often the logs repeat it" do
    sign_in @user

    assert_api_response :put, 200, api_path: MATCH_PATH, body: {names: ["5CA 'Akura'", "5ca 'akura'", " "]} do
      assert_equal ["5CA 'Akura'"], parsed_body.pluck("name")
    end
  end

  test "PUT match resolves a translated name through its localisation keys" do
    @helmet_a.update!(name_key: "item_name_argus_helmet")
    sign_in @user

    assert_api_response :put, 200, api_path: MATCH_PATH,
      body: {names: ["Casco Argus"], nameKeys: [{name: "Casco Argus", keys: ["item_Name_argus_helmet", "item_name_unrelated"]}]} do
      assert_equal [@helmet_a.slug], parsed_body.first["blueprints"].pluck("slug")
    end
  end

  test "PUT match offers both what a name means in English and what its translation means" do
    @akura.update!(name_key: "item_name_akura")
    @rifle.update!(name_key: "item_name_rifle")
    sign_in @user

    assert_api_response :put, 200, api_path: MATCH_PATH,
      body: {names: ["5CA 'Akura'"], nameKeys: [{name: "5CA 'Akura'", keys: ["item_name_rifle", "item_name_akura"]}]} do
      assert_equal [@akura.slug, @rifle.slug].sort, parsed_body.first["blueprints"].pluck("slug").sort
    end
  end

  test "PUT match flags a wanted blueprint" do
    create(:user_blueprint, user: @user, blueprint: @akura, wanted: true)
    sign_in @user

    assert_api_response :put, 200, api_path: MATCH_PATH, body: {names: ["5CA 'Akura'"]} do
      assert_equal [{"owned" => false, "wanted" => true}], parsed_body.first["blueprints"].map { |option| option.slice("owned", "wanted") }
    end
  end

  test "PUT match needs a user" do
    assert_api_response :put, 401, api_path: MATCH_PATH, body: {names: ["5CA 'Akura'"]}
  end

  test "PUT import marks new blueprints owned, promotes wanted ones and records the run" do
    create(:user_blueprint, user: @user, blueprint: @rifle)
    create(:user_blueprint, user: @user, blueprint: @helmet_a, wanted: true)
    sign_in @user

    assert_api_response :put, 200, api_path: IMPORT_PATH,
      body: {slugs: [@akura.slug, @rifle.slug, @helmet_a.slug], unmatchedNames: ["Nothing Like It"]} do
      assert_equal 2, parsed_body["imported"]
      assert_equal 1, parsed_body["unchanged"]

      import = Imports::BlueprintLogImport.find(parsed_body["importId"])

      assert_predicate import, :finished?
      assert_equal @user, import.user
      assert_equal(
        {imported: ["5CA 'Akura'", "Argus Helmet Black/Silver"], unchanged: ["Custodian \"Desert Shadow\" SMG"], missing_blueprints: ["Nothing Like It"]},
        import.result_details
      )
    end

    assert_equal [@akura, @rifle, @helmet_a].map(&:id).sort, UserBlueprint.owned.where(user: @user).pluck(:blueprint_id).sort
    assert_empty UserBlueprint.wanted.where(user: @user)
  end

  test "PUT import leaves blueprints missing from the logs owned" do
    create(:user_blueprint, user: @user, blueprint: @rifle)
    sign_in @user

    assert_api_response :put, 200, api_path: IMPORT_PATH, body: {slugs: [@akura.slug]}

    assert_equal [@akura, @rifle].map(&:id).sort, UserBlueprint.owned.where(user: @user).pluck(:blueprint_id).sort
  end

  test "PUT import ignores slugs that are no blueprint" do
    sign_in @user

    assert_api_response :put, 200, api_path: IMPORT_PATH, body: {slugs: ["no-such-blueprint"]} do
      assert_equal 0, parsed_body["imported"]
    end
  end

  test "PUT import shows up in the user's imports" do
    sign_in @user

    put "/api/v1/hangar/blueprint-imports", params: {slugs: [@akura.slug]}, as: :json
    import_id = response.parsed_body["importId"]

    get "/api/v1/imports/#{import_id}"

    assert_response :ok
    assert_equal "Imports::BlueprintLogImport", response.parsed_body["type"]
    assert_equal ["5CA 'Akura'"], response.parsed_body.dig("details", "imported")
  end

  test "PUT match and import refuse a token without the hangar scope" do
    headers = oauth_headers_for(@user, scopes: "fleet")

    assert_api_response :put, 401, api_path: MATCH_PATH, headers: headers, body: {names: ["5CA 'Akura'"]}
    assert_api_response :put, 401, api_path: IMPORT_PATH, headers: headers, body: {slugs: [@akura.slug]}

    assert_empty UserBlueprint.where(user: @user)
  end

  test "PUT import needs a user" do
    assert_api_response :put, 401, api_path: IMPORT_PATH, body: {slugs: [@akura.slug]}
  end
end
