# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FeedbacksTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/feedback" do
    post("Send feedback") do
      operationId "createFeedback"
      tags "Feedback"
      consumes "application/json"
      produces "application/json"
      security [{SessionCookie: []}]

      request_body required: true, schema: ::V1::Schemas::Inputs::FeedbackInput

      response(201, "successful") do
        schema ::V1::Schemas::Feedbacks::Feedback
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/feedback" do
    get("Your feedback") do
      operationId "feedbacks"
      tags "Feedback"
      produces "application/json"
      security [{SessionCookie: []}]

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema ::V1::Schemas::Feedbacks::FeedbackList
      end

      response(401, "unauthorized") do
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
      security [{SessionCookie: []}]

      response(200, "successful") do
        schema ::V1::Schemas::Feedbacks::Feedback
      end

      response(401, "unauthorized") do
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
      security [{SessionCookie: []}]

      request_body required: true, schema: ::V1::Schemas::Inputs::FeedbackReplyInput

      response(201, "successful") do
        schema ::V1::Schemas::Feedbacks::Feedback
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "POST /feedback stores the message with its feature and page" do
    sign_in @user
    feature = FeatureFlags::Registry.current.names.first

    assert_difference -> { @user.feedbacks.count }, 1 do
      post "/api/v1/feedback",
        params: {message: "Works well", featureName: feature, pagePath: "/hangar/planner"},
        as: :json
    end

    assert_response :created
    feedback = @user.feedbacks.last
    assert_equal "Works well", feedback.message
    assert_equal feature, feedback.feature_name
    assert_equal "/hangar/planner", feedback.page_path
    assert feedback.open?
  end

  test "POST /feedback without a feature is general feedback" do
    sign_in @user

    post "/api/v1/feedback", params: {message: "Hello"}, as: :json

    assert_response :created
    assert_nil @user.feedbacks.last.feature_name
  end

  test "POST /feedback refuses an unknown feature" do
    sign_in @user

    assert_no_difference -> { Feedback.count } do
      post "/api/v1/feedback", params: {message: "Hello", featureName: "no-such-flag"}, as: :json
    end

    assert_response :bad_request
  end

  test "POST /feedback refuses an empty message" do
    sign_in @user

    post "/api/v1/feedback", params: {message: ""}, as: :json

    assert_response :bad_request
  end

  test "POST /feedback needs a signed-in user" do
    post "/api/v1/feedback", params: {message: "Hello"}, as: :json

    assert_response :unauthorized
  end

  test "GET /feedback lists only your own feedback" do
    mine = create(:feedback, user: @user)
    create(:feedback)
    sign_in @user

    get "/api/v1/feedback"

    assert_response :ok
    assert_equal [mine.id], response.parsed_body["items"].pluck("id")
    assert_equal "open", response.parsed_body["items"].first["state"]
  end

  test "GET /feedback/:id shows the conversation" do
    feedback = create(:feedback, user: @user)
    create(:feedback_reply, feedback:, from_admin: true, body: "Which hangar size?")
    sign_in @user

    get "/api/v1/feedback/#{feedback.id}"

    assert_response :ok
    reply = response.parsed_body["replies"].sole
    assert_equal "Which hangar size?", reply["body"]
    assert reply["fromAdmin"]
  end

  test "GET /feedback/:id hides other users' feedback" do
    sign_in @user

    get "/api/v1/feedback/#{create(:feedback).id}"

    assert_response :not_found
  end

  test "POST /feedback/:id/replies answers as the user" do
    feedback = create(:feedback, user: @user)
    sign_in @user

    post "/api/v1/feedback/#{feedback.id}/replies", params: {body: "About 40 ships"}, as: :json

    assert_response :created
    reply = feedback.replies.sole
    assert_not reply.from_admin
    assert_equal "About 40 ships", reply.body
  end

  test "POST /feedback/:id/replies refuses someone else's feedback" do
    sign_in @user

    post "/api/v1/feedback/#{create(:feedback).id}/replies", params: {body: "Hi"}, as: :json

    assert_response :not_found
  end
end
