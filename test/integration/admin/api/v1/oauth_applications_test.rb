# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::OauthApplicationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/oauth-applications" do
    post("Create OAuth Application") do
      operationId "createOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::OauthApplicationInput

      response(201, "successful") do
        schema ::Admin::V1::Schemas::OauthApplication
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("OAuth Applications list") do
      operationId "oauthApplications"
      tags "OauthApplications"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: ::Admin::V1::Schemas::Queries::OauthApplicationQuery, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::OauthApplications
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/oauth-applications/{id}" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    delete("Destroy OAuth Application") do
      operationId "destroyOauthApplication"
      tags "OauthApplications"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::OauthApplication
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

    get("OAuth Application detail") do
      operationId "oauthApplication"
      tags "OauthApplications"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::OauthApplication
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

    put("Update OAuth Application") do
      operationId "updateOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::OauthApplicationUpdateInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::OauthApplication
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

  api_path "/oauth-applications/reject-bulk" do
    put("Reject OAuth Applications in bulk") do
      operationId "rejectOauthApplicationsBulk"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::OauthApplicationRejectBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::OauthApplicationBulkResult
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/oauth-applications/{id}/approve" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    put("Approve OAuth Application") do
      operationId "approveOauthApplication"
      tags "OauthApplications"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::OauthApplication
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

  api_path "/oauth-applications/{id}/reject" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    put("Reject OAuth Application") do
      operationId "rejectOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::OauthApplicationRejectInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::OauthApplication
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

  setup do
    @user = create(:admin_user, resource_access: [:oauth_applications])
  end
  # REJECT BULK
  test "PUT /oauth-applications/reject-bulk refuses the named applications" do
    pending_applications = create_list(:oauth_application, 3, :pending)
    untouched = create(:oauth_application, :pending)
    sign_in @user

    body = {ids: pending_applications.map(&:id), rejectionReason: "Bulk refusal"}
    assert_api_response :put, 200, api_path: "/oauth-applications/reject-bulk", body: body do
      assert_equal 3, parsed_body["count"]
    end

    pending_applications.each do |application|
      assert_predicate application.reload, :rejected?
      assert_equal "Bulk refusal", application.rejection_reason
      assert_not application.usable_as_client?
    end

    assert_predicate untouched.reload, :pending?
  end

  # The other reading of a body naming neither is `update_all` over the table.
  test "PUT /oauth-applications/reject-bulk selects nothing when given neither ids nor all" do
    application = create(:oauth_application, :pending)
    sign_in @user

    assert_api_response :put, 200, api_path: "/oauth-applications/reject-bulk", body: {rejectionReason: "Bulk refusal"} do
      assert_equal 0, parsed_body["count"]
    end

    assert_predicate application.reload, :pending?
  end

  test "PUT /oauth-applications/reject-bulk takes everything the filter matches when asked" do
    create_list(:oauth_application, 2, :pending)
    approved = create(:oauth_application)
    sign_in @user

    body = {all: true, q: {aasmStateEq: "pending"}, rejectionReason: "Bulk refusal"}
    assert_api_response :put, 200, api_path: "/oauth-applications/reject-bulk", body: body do
      assert_equal 2, parsed_body["count"]
    end

    assert_predicate approved.reload, :approved?
  end

  test "PUT /oauth-applications/reject-bulk without a reason is refused" do
    application = create(:oauth_application, :pending)
    sign_in @user

    assert_api_response :put, 400, api_path: "/oauth-applications/reject-bulk", body: {ids: [application.id], rejectionReason: ""}

    assert_predicate application.reload, :pending?
  end

  test "PUT /oauth-applications/reject-bulk returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/oauth-applications/reject-bulk", body: {ids: [], rejectionReason: "x"}
  end

  # APPROVE
  test "PUT /oauth-applications/:id/approve makes the application usable" do
    application = create(:oauth_application, :pending)
    sign_in @user

    assert_api_response :put, 200, api_path: "/oauth-applications/{id}/approve", path_params: {id: application.id} do
      assert_equal "approved", parsed_body["state"]
    end

    assert application.reload.usable_as_client?
    assert_equal @user.id, application.reviewed_by_id
  end

  test "PUT /oauth-applications/:id/approve returns 401 when not signed in" do
    application = create(:oauth_application, :pending)

    assert_api_response :put, 401, api_path: "/oauth-applications/{id}/approve", path_params: {id: application.id}
  end

  test "PUT /oauth-applications/:id/approve returns 403 for admin without access" do
    application = create(:oauth_application, :pending)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/oauth-applications/{id}/approve", path_params: {id: application.id}
  end

  # REJECT
  test "PUT /oauth-applications/:id/reject records the reason" do
    application = create(:oauth_application, :pending)
    sign_in @user

    body = {rejectionReason: "Redirect target is not under the stated domain"}
    assert_api_response :put, 200, api_path: "/oauth-applications/{id}/reject", path_params: {id: application.id}, body: body do
      assert_equal "rejected", parsed_body["state"]
      assert_equal "Redirect target is not under the stated domain", parsed_body["rejectionReason"]
    end

    assert_not application.reload.usable_as_client?
  end

  test "PUT /oauth-applications/:id/reject without a reason is refused" do
    application = create(:oauth_application, :pending)
    sign_in @user

    assert_api_response :put, 400, api_path: "/oauth-applications/{id}/reject", path_params: {id: application.id}, body: {rejectionReason: ""}

    assert_predicate application.reload, :pending?
  end

  # POST
  test "POST /oauth-applications creates an application" do
    sign_in @user

    body = {name: "Admin App", redirectUri: "https://example.com/callback", confidential: true}
    assert_api_response :post, 201, body: body do
      assert_equal "Admin App", parsed_body["name"]
    end
  end

  test "POST /oauth-applications returns 401 when not signed in" do
    body = {name: "x", redirectUri: "https://example.com/callback", confidential: true}
    assert_api_response :post, 401, body: body
  end

  test "POST /oauth-applications returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    body = {name: "x", redirectUri: "https://example.com/callback", confidential: true}
    assert_api_response :post, 403, body: body
  end

  # GET list
  test "GET /oauth-applications lists applications" do
    create_list(:oauth_application, 3)
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /oauth-applications returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /oauth-applications returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE
  test "DELETE /oauth-applications/:id destroys the application" do
    app = create(:oauth_application)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: app.id}
  end

  test "DELETE /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application)

    assert_api_response :delete, 401, path_params: {id: app.id}
  end

  test "DELETE /oauth-applications/:id returns 403 for admin without access" do
    app = create(:oauth_application)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: app.id}
  end

  # GET single
  test "GET /oauth-applications/:id returns the application" do
    app = create(:oauth_application)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: app.id}
  end

  test "GET /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application)

    assert_api_response :get, 401, path_params: {id: app.id}
  end

  test "GET /oauth-applications/:id returns 403 for admin without access" do
    app = create(:oauth_application)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: app.id}
  end

  # PUT
  test "PUT /oauth-applications/:id updates the application" do
    app = create(:oauth_application)
    sign_in @user

    assert_api_response :put, 200, api_path: "/oauth-applications/{id}", path_params: {id: app.id}, body: {name: "Updated Admin App"} do
      assert_equal "Updated Admin App", parsed_body["name"]
    end
  end

  test "PUT /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, api_path: "/oauth-applications/{id}", path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application)

    assert_api_response :put, 401, api_path: "/oauth-applications/{id}", path_params: {id: app.id}, body: {name: "x"}
  end

  test "PUT /oauth-applications/:id returns 403 for admin without access" do
    app = create(:oauth_application)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/oauth-applications/{id}", path_params: {id: app.id}, body: {name: "x"}
  end
end
