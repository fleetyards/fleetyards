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
end
