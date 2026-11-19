# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FeedbacksTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/feedback" do
    get("Feedback list") do
      operationId "feedbacks"
      tags "Feedback"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: ::Admin::V1::Schemas::Queries::FeedbackQuery, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Feedbacks
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/feedback/{id}" do
    parameter name: "id", in: :path, description: "Feedback id", schema: {type: :string, format: :uuid}

    get("Feedback with its replies") do
      operationId "feedback"
      tags "Feedback"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Feedback
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/feedback/{id}/replies" do
    parameter name: "id", in: :path, description: "Feedback id", schema: {type: :string, format: :uuid}

    post("Reply to feedback") do
      operationId "replyToFeedback"
      tags "Feedback"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::FeedbackReplyInput

      response(201, "successful") do
        schema ::Admin::V1::Schemas::Feedback
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/feedback/{id}/resolve" do
    parameter name: "id", in: :path, description: "Feedback id", schema: {type: :string, format: :uuid}

    put("Resolve feedback") do
      operationId "resolveFeedback"
      tags "Feedback"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Feedback
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/feedback/{id}/reopen" do
    parameter name: "id", in: :path, description: "Feedback id", schema: {type: :string, format: :uuid}

    put("Reopen feedback") do
      operationId "reopenFeedback"
      tags "Feedback"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Feedback
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:admin_user, resource_access: [:feedback])
  end

  test "GET /feedback lists feedback newest first" do
    older = create(:feedback, created_at: 2.days.ago)
    newer = create(:feedback)
    sign_in @admin

    get "/admin/api/v1/feedback"

    assert_response :ok
    assert_equal [newer.id, older.id], response.parsed_body["items"].pluck("id")
    assert_equal newer.user.username, response.parsed_body["items"].first["username"]
  end

  test "GET /feedback filters by state and feature" do
    feature = FeatureFlags::Registry.current.names.first
    wanted = create(:feedback, feature_name: feature)
    create(:feedback, :resolved, feature_name: feature)
    create(:feedback)
    sign_in @admin

    get "/admin/api/v1/feedback", params: {q: {aasmStateEq: "open", featureNameEq: feature}}

    assert_response :ok
    assert_equal [wanted.id], response.parsed_body["items"].pluck("id")
  end

  test "GET /feedback returns 403 without the feedback privilege" do
    sign_in create(:admin_user, resource_access: [:users])

    get "/admin/api/v1/feedback"

    assert_response :forbidden
  end

  test "PUT /feedback/:id/resolve records who resolved it" do
    feedback = create(:feedback)
    sign_in @admin

    put "/admin/api/v1/feedback/#{feedback.id}/resolve"

    assert_response :ok
    feedback.reload
    assert feedback.resolved?
    assert_equal @admin, feedback.resolved_by
    assert feedback.resolved_at
    assert_equal @admin.username, response.parsed_body["resolvedByName"]
  end

  test "PUT /feedback/:id/resolve refuses feedback that is already resolved" do
    feedback = create(:feedback, :resolved)
    sign_in @admin

    put "/admin/api/v1/feedback/#{feedback.id}/resolve"

    assert_response :bad_request
  end

  test "PUT /feedback/:id/reopen clears the resolution" do
    feedback = create(:feedback, :resolved, resolved_by: @admin)
    sign_in @admin

    put "/admin/api/v1/feedback/#{feedback.id}/reopen"

    assert_response :ok
    feedback.reload
    assert feedback.open?
    assert_nil feedback.resolved_by
    assert_nil feedback.resolved_at
  end

  test "PUT /feedback/:id/resolve returns 404 for an unknown id" do
    sign_in @admin

    put "/admin/api/v1/feedback/#{SecureRandom.uuid}/resolve"

    assert_response :not_found
  end

  test "GET /feedback/:id shows the conversation with who answered" do
    feedback = create(:feedback)
    create(:feedback_reply, feedback:, from_admin: true, admin_user: @admin, body: "Which ship?")
    create(:feedback_reply, feedback:, body: "The Carrack")
    sign_in @admin

    get "/admin/api/v1/feedback/#{feedback.id}"

    assert_response :ok
    assert_equal ["Which ship?", "The Carrack"], response.parsed_body["replies"].pluck("body")
    assert_equal @admin.username, response.parsed_body["replies"].first["adminName"]
  end

  test "POST /feedback/:id/replies answers the user and notifies them" do
    feedback = create(:feedback)
    sign_in @admin

    assert_difference -> { Notification.where(user: feedback.user, notification_type: "feedback_reply").count }, 1 do
      post "/admin/api/v1/feedback/#{feedback.id}/replies", params: {body: "Which ship?"}, as: :json
    end

    assert_response :created
    reply = feedback.replies.sole
    assert reply.from_admin
    assert_equal @admin, reply.admin_user
  end

  test "POST /feedback/:id/replies refuses an empty reply" do
    sign_in @admin

    post "/admin/api/v1/feedback/#{create(:feedback).id}/replies", params: {body: ""}, as: :json

    assert_response :bad_request
  end
end
