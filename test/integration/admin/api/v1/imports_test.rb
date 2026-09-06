# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ImportsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/imports" do
    get("Imports list") do
      operationId "imports"
      description "Get a List of Imports"
      produces "application/json"
      tags "Imports"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Import.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::ImportQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Imports
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/imports/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id", required: true

    get("Import Detail") do
      operationId "import"
      tags "Imports"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Import
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

  api_path "/imports/{id}/cleanup" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id", required: true

    put("Clean up a stuck Import") do
      operationId "cleanupImport"
      description "Mark a running Import as failed, for a job that never reported back"
      tags "Imports"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Import
      end

      response(422, "unprocessable entity") do
        schema ::Shared::V1::Schemas::StandardError
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

  api_path "/imports/cleanup-bulk" do
    put("Clean up a selection of Imports") do
      operationId "cleanupBulkImports"
      description "Mark the running Imports among a selection as failed"
      tags "Imports"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::ImportBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::ImportCleanupResult
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:imports])
  end

  # GET /imports
  test "GET /imports lists all imports" do
    create_list(:import, 10)
    sign_in @user

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /imports filters by type query" do
    imports = create_list(:import, 10)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"typeEq" => imports.first.type}} do
      assert_equal Import.where(type: imports.first.type).count, parsed_body["items"].count
    end
  end

  test "GET /imports filters by admin_user requester" do
    admin_user = create(:admin_user)
    admin_import = create(:import, :model_import, admin_user: admin_user)
    create(:import, :hangar_sync, user: create(:user))
    create(:import, :model_import)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"adminUserUsernameIn" => [admin_user.username]}} do
      assert_equal [admin_import.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /imports filters by user requester" do
    hangar_user = create(:user)
    user_import = create(:import, :hangar_sync, user: hangar_user)
    create(:import, :model_import, admin_user: create(:admin_user))
    create(:import, :model_import)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"userUsernameIn" => [hangar_user.username]}} do
      assert_equal [user_import.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /imports filters by includeSystem" do
    create(:import, :model_import, admin_user: create(:admin_user))
    create(:import, :hangar_sync, user: create(:user))
    system_import = create(:import, :model_import)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"includeSystem" => "true"}} do
      assert_equal [system_import.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /imports OR-combines requester filters" do
    admin_user = create(:admin_user)
    admin_import = create(:import, :model_import, admin_user: admin_user)
    create(:import, :hangar_sync, user: create(:user))
    system_import = create(:import, :model_import)
    sign_in @user

    assert_api_response :get, 200,
      params: {q: {"adminUserUsernameIn" => [admin_user.username], "includeSystem" => "true"}} do
      assert_equal [admin_import.id, system_import.id].sort, parsed_body["items"].pluck("id").sort
    end
  end

  test "GET /imports returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  # GET /imports/{id}
  test "GET /imports/{id} returns the import" do
    import = create(:import)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: import.id}
  end

  test "GET /imports/{id} returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /imports/{id} returns 401 when not signed in" do
    import = create(:import)

    assert_api_response :get, 401, path_params: {id: import.id}
  end

  test "GET /imports/{id} returns 403 for admin without access" do
    import = create(:import)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: import.id}
  end

  # PUT /imports/{id}/cleanup
  test "PUT /imports/{id}/cleanup marks a running import as failed" do
    import = create(:import, aasm_state: "started", started_at: 5.hours.ago)
    sign_in @user

    assert_api_response :put, 200, api_path: "/imports/{id}/cleanup", path_params: {id: import.id} do
      assert_equal "failed", parsed_body["status"]
      assert_includes parsed_body["info"], @user.username
    end

    assert_predicate import.reload, :failed?
    assert_not_nil import.failed_at
  end

  test "PUT /imports/{id}/cleanup keeps the info the run had already reported" do
    import = create(:import, aasm_state: "started", started_at: 5.hours.ago, info: "142 models read")
    sign_in @user

    assert_api_response :put, 200, api_path: "/imports/{id}/cleanup", path_params: {id: import.id}

    assert_includes import.reload.info, "142 models read"
  end

  test "PUT /imports/{id}/cleanup refuses an import that is not running" do
    import = create(:import, aasm_state: "finished", finished_at: 1.hour.ago)
    sign_in @user

    assert_api_response :put, 422, api_path: "/imports/{id}/cleanup", path_params: {id: import.id}

    assert_predicate import.reload, :finished?
  end

  test "PUT /imports/{id}/cleanup notifies nobody" do
    import = create(:import, aasm_state: "started", started_at: 5.hours.ago)
    sign_in @user

    assert_no_difference -> { AdminNotification.count } do
      assert_api_response :put, 200, api_path: "/imports/{id}/cleanup", path_params: {id: import.id}
    end
  end

  test "PUT /imports/{id}/cleanup returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, api_path: "/imports/{id}/cleanup",
      path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "PUT /imports/{id}/cleanup returns 401 when not signed in" do
    import = create(:import, aasm_state: "started", started_at: 5.hours.ago)

    assert_api_response :put, 401, api_path: "/imports/{id}/cleanup", path_params: {id: import.id}
  end

  test "PUT /imports/{id}/cleanup returns 403 for admin without access" do
    import = create(:import, aasm_state: "started", started_at: 5.hours.ago)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/imports/{id}/cleanup", path_params: {id: import.id}
  end

  # PUT /imports/cleanup-bulk
  test "PUT /imports/cleanup-bulk fails the selected imports and counts them" do
    selected = create_list(:import, 2, aasm_state: "started", started_at: 5.hours.ago)
    untouched = create(:import, aasm_state: "started", started_at: 5.hours.ago)
    sign_in @user

    assert_api_response :put, 200, api_path: "/imports/cleanup-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
    end

    assert_equal %w[failed failed], selected.map { |import| import.reload.aasm_state }
    assert_predicate untouched.reload, :started?
  end

  # A selection made minutes ago can hold a run that has since finished, and one
  # of those must not take the whole batch down.
  test "PUT /imports/cleanup-bulk skips a selected import that is no longer running" do
    running = create(:import, aasm_state: "started", started_at: 5.hours.ago)
    finished = create(:import, aasm_state: "finished", finished_at: 1.minute.ago)
    sign_in @user

    assert_api_response :put, 200, api_path: "/imports/cleanup-bulk",
      body: {ids: [running.id, finished.id]} do
      assert_equal 1, parsed_body["count"]
    end

    assert_predicate running.reload, :failed?
    assert_predicate finished.reload, :finished?
  end

  test "PUT /imports/cleanup-bulk reports zero when nothing in the selection was running" do
    finished = create(:import, aasm_state: "finished", finished_at: 1.minute.ago)
    sign_in @user

    assert_api_response :put, 200, api_path: "/imports/cleanup-bulk", body: {ids: [finished.id]} do
      assert_equal 0, parsed_body["count"]
    end
  end

  test "PUT /imports/cleanup-bulk returns 401 when not signed in" do
    assert_api_response :put, 401, api_path: "/imports/cleanup-bulk", body: {ids: []}
  end

  test "PUT /imports/cleanup-bulk returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/imports/cleanup-bulk", body: {ids: []}
  end
end
