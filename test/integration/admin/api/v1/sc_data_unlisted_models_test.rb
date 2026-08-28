# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ScDataUnlistedModelsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/unlisted-models" do
    get("Unlisted models list") do
      operationId "scDataUnlistedModels"
      tags "ScDataUnlistedModels"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query,
        schema: {type: :string, default: ScDataUnlistedModel.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::ScDataUnlistedModelQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::ScDataUnlistedModels::ScDataUnlistedModels
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/unlisted-models/{id}/link" do
    parameter name: "id", in: :path, description: "Unlisted model id",
      schema: {type: :string, format: :uuid}, required: true

    post("Link to a model already in the catalogue") do
      operationId "scDataUnlistedModelLink"
      tags "ScDataUnlistedModels"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::ScDataUnlistedModelLinkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::ScDataUnlistedModel
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  %w[ignore mark-as-paint create-model reset].each do |action|
    api_path "/unlisted-models/{id}/#{action}" do
      parameter name: "id", in: :path, description: "Unlisted model id",
        schema: {type: :string, format: :uuid}, required: true

      post(action.tr("-", " ").titleize) do
        operationId "scDataUnlistedModel#{action.tr("-", "_").camelize}"
        tags "ScDataUnlistedModels"
        produces "application/json"

        response(200, "successful") do
          schema ::Admin::V1::Schemas::ScDataUnlistedModel
        end

        response(400, "bad request") do
          schema ::Shared::V1::Schemas::ValidationError
        end

        response(404, "not found") do
          schema ::Shared::V1::Schemas::StandardError
        end

        response(403, "forbidden") do
          schema ::Shared::V1::Schemas::StandardError
        end

        response(401, "unauthorized") do
          schema ::Shared::V1::Schemas::StandardError
        end
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:models])
    @entry = create(
      :sc_data_unlisted_model,
      identifier: "krig_s65_stingray", name: "Kruger S-65 Stingray", manufacturer_code: "KRIG"
    )
  end

  test "GET /unlisted-models lists what nobody has decided about" do
    decided = create(:sc_data_unlisted_model, :decided)

    sign_in @user

    assert_api_response :get, 200 do
      identifiers = parsed_body["items"].map { |item| item["identifier"] }

      assert_includes identifiers, "krig_s65_stingray"
      assert_not_includes identifiers, decided.identifier
    end
  end

  test "GET /unlisted-models reaches the decided ones when asked" do
    decided = create(:sc_data_unlisted_model, :decided)

    sign_in @user

    assert_api_response :get, 200, params: {q: {"decisionEq" => "ignored"}} do
      assert_equal [decided.identifier], parsed_body["items"].map { |item| item["identifier"] }
    end
  end

  test "GET /unlisted-models needs the models privilege" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "GET /unlisted-models is not public" do
    assert_api_response :get, 401
  end

  test "POST ignore records the decision and drops it from the list" do
    sign_in @user
    assert_api_response :post, 200, path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/ignore" do
      assert_equal "ignored", parsed_body["decision"]
    end

    assert_predicate @entry.reload.decision, :present?
    assert_empty ScDataUnlistedModel.undecided
  end

  test "POST mark-as-paint records that it belongs on an existing model" do
    sign_in @user
    assert_api_response :post, 200, path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/mark-as-paint" do
      assert_equal "paint", parsed_body["decision"]
    end
  end

  # The export gives a name, the identifier gives a manufacturer, and nothing
  # else is guessed -- the next load fills in the mechanics.
  test "POST create-model creates the ship and links it" do
    sign_in @user
    create(:manufacturer, code: "KRIG", name: "Kruger Intergalactic")

    assert_difference("Model.count", 1) do
      assert_api_response :post, 200, path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/create-model" do
        assert_equal "model", parsed_body["decision"]
        assert_equal "S-65 Stingray", parsed_body.dig("model", "name")
      end
    end

    model = @entry.reload.model
    assert_equal "krig_s65_stingray", model.sc_key
    assert_equal "KRIG", model.manufacturer.code
    assert_predicate model, :hidden?, "a new ship stays out of the catalogue until an admin fills it in"
  end

  # The export writes "Kruger S-65 Stingray" where the catalogue says
  # "S-65 Stingray". Taking the export name as-is would break the convention and
  # slip past Model's name uniqueness, which is scoped to the manufacturer.
  test "the suggested name drops the manufacturer the export prefixes" do
    create(:manufacturer, code: "KRIG", name: "Kruger Intergalactic")

    sign_in @user

    assert_api_response :get, 200 do
      entry = parsed_body["items"].find { |item| item["identifier"] == "krig_s65_stingray" }

      assert_equal "S-65 Stingray", entry["suggestedName"]
    end
  end

  # Only a quarter of models carry an `sc_key`, so a ship whose identifier comes
  # from its slug lands in this list even though the catalogue has it.
  test "POST create-model refuses when a ship of that name already exists" do
    manufacturer = create(:manufacturer, code: "KRIG", name: "Kruger Intergalactic")
    existing = create(:model, manufacturer:, name: "S-65 Stingray")

    assert_no_difference("Model.count") do
      sign_in @user

      assert_api_response :post, 400,
        path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/create-model"
    end

    assert_predicate @entry.reload.decision, :blank?
    assert_equal existing, @entry.existing_model
  end

  test "the list names the ship and the paint already in the catalogue" do
    manufacturer = create(:manufacturer, code: "KRIG", name: "Kruger Intergalactic")
    create(:model, manufacturer:, name: "S-65 Stingray")

    base = create(:model, name: "Gladius", sc_key: "aegs_gladius")
    paint = create(:model_paint, model: base, name: "Dunlevy")
    create(
      :sc_data_unlisted_model,
      identifier: "aegs_gladius_dunlevy", name: "Aegis Gladius Dunlevy",
      manufacturer_code: "AEGS", base_model: base, comparison: "refitted"
    )

    sign_in @user

    assert_api_response :get, 200 do
      items = parsed_body["items"].index_by { |item| item["identifier"] }

      assert_equal "S-65 Stingray", items["krig_s65_stingray"].dig("existingModel", "name")
      assert_equal paint.name, items["aegs_gladius_dunlevy"].dig("existingPaint", "name")
    end
  end

  # `belongs_to :manufacturer` is required, and an unresolved prefix means either
  # a new company or a file that is not a ship.
  test "POST create-model refuses when the prefix resolves to no manufacturer" do
    sign_in @user
    orphan = create(:sc_data_unlisted_model, identifier: "orbital_sentry_pu_uee", manufacturer_code: nil)

    assert_no_difference("Model.count") do
      assert_api_response :post, 400, path_params: {id: orphan.id}, api_path: "/unlisted-models/{id}/create-model"
    end
  end

  test "POST create-model refuses a second time" do
    sign_in @user
    create(:manufacturer, code: "KRIG")
    @entry.create_model!

    assert_no_difference("Model.count") do
      assert_api_response :post, 400, path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/create-model"
    end
  end

  # The model a create left behind stays: deleting a ship is its own action, and
  # a hangar entry may already point at it.
  test "POST reset returns it to the list without deleting the model" do
    sign_in @user
    create(:manufacturer, code: "KRIG")
    @entry.create_model!

    assert_no_difference("Model.count") do
      assert_api_response :post, 200, path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/reset" do
        assert_nil parsed_body["decision"]
      end
    end

    assert_includes ScDataUnlistedModel.undecided, @entry.reload
  end

  test "POST ignore needs the models privilege" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/ignore"
  end

  test "POST ignore is not public" do
    assert_api_response :post, 401, path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/ignore"
  end

  test "POST ignore reports a missing entry" do
    sign_in @user

    assert_api_response :post, 404, path_params: {id: SecureRandom.uuid}, api_path: "/unlisted-models/{id}/ignore"
  end

  # The answer to "it is already in the catalogue, under a name the game files
  # spell differently". Without it the entry comes back every patch.
  test "POST link records which ship in the catalogue it already is" do
    existing = create(:model, name: "S-65 Stingray")

    sign_in @user

    assert_no_difference("Model.count") do
      assert_api_response :post, 200,
        path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/link",
        body: {modelId: existing.id} do
        assert_equal "model", parsed_body["decision"]
        assert_equal "S-65 Stingray", parsed_body.dig("model", "name")
      end
    end

    assert_equal existing, @entry.reload.model
    assert_empty ScDataUnlistedModel.undecided
  end

  # Repointing a ship's identifier at a variant's file would make the loader read
  # the wrong one, so linking records the answer and leaves `sc_key` alone.
  test "POST link leaves the linked ship's own identifier alone" do
    existing = create(:model, name: "S-65 Stingray", sc_key: nil)

    sign_in @user

    assert_api_response :post, 200,
      path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/link",
      body: {modelId: existing.id}

    assert_nil existing.reload.sc_key
  end

  test "POST link refuses a second decision" do
    existing = create(:model, name: "S-65 Stingray")
    @entry.decide!("ignored")

    sign_in @user

    assert_api_response :post, 400,
      path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/link",
      body: {modelId: existing.id}
  end

  test "POST link reports a model that is not there" do
    sign_in @user

    assert_api_response :post, 404,
      path_params: {id: @entry.id}, api_path: "/unlisted-models/{id}/link",
      body: {modelId: SecureRandom.uuid}
  end
end
