# frozen_string_literal: true

require "test_helper"

# Lives outside test/integration/api/v1 on purpose: this is Ko-fi's callback
# surface, not public API, so it must not contribute to the generated OpenAPI
# schema.
class KofiWebhookTest < ActionDispatch::IntegrationTest
  PATH = "/kofi/webhook"
  TOKEN = "kofi-verification-token"

  setup do
    Rails.application.credentials.stubs(:dig).with(:kofi, :verification_token).returns(TOKEN)
  end

  def payload(overrides = {})
    {
      "verification_token" => TOKEN,
      "message_id" => "msg-1",
      "timestamp" => "2026-06-01T10:00:00Z",
      "type" => "Donation",
      "is_public" => "true",
      "from_name" => "Jo Example",
      "message" => "keep it up!",
      "amount" => "5.00",
      "email" => "jo@example.test",
      "currency" => "EUR",
      "is_subscription_payment" => "false",
      "kofi_transaction_id" => "txn-1"
    }.merge(overrides)
  end

  def post_webhook(body)
    post PATH, params: {data: body.to_json}
  end

  test "accepts a verified payment and records it" do
    assert_difference -> { SupporterContribution.count }, 1 do
      post_webhook(payload)
    end

    assert_response :ok
    assert_equal "Jo Example", SupporterContribution.find_by(kofi_transaction_id: "txn-1").name
  end

  test "links the donor when their message carries a claim key" do
    user = create(:user, confirmed_at: Time.current)
    key = user.ensure_claim_key!

    post_webhook(payload("message" => "thanks! #{key}"))

    assert_response :ok
    assert_equal user, SupporterContribution.find_by(kofi_transaction_id: "txn-1").user
  end

  test "refuses a wrong verification token and records nothing" do
    assert_no_difference -> { SupporterContribution.count } do
      post_webhook(payload("verification_token" => "not-the-token"))
    end

    assert_response :unauthorized
  end

  test "refuses a missing verification token" do
    assert_no_difference -> { SupporterContribution.count } do
      post_webhook(payload.except("verification_token"))
    end

    assert_response :unauthorized
  end

  # Without a configured token every request would verify against "" and the
  # endpoint would accept anything.
  test "refuses everything when no token is configured" do
    Rails.application.credentials.stubs(:dig).with(:kofi, :verification_token).returns(nil)

    assert_no_difference -> { SupporterContribution.count } do
      post_webhook(payload)
    end

    assert_response :unauthorized
  end

  test "a replayed delivery does not duplicate the contribution" do
    post_webhook(payload)

    assert_no_difference -> { SupporterContribution.count } do
      post_webhook(payload)
    end

    assert_response :ok
  end

  # 401 rather than 400: an unverifiable request is unverifiable, and there is
  # nothing to gain from telling an anonymous caller which half was wrong.
  test "refuses a body that is not JSON, and one that is missing entirely" do
    assert_no_difference -> { SupporterContribution.count } do
      post PATH, params: {data: "not json at all"}
      assert_response :unauthorized

      post PATH, params: {}
      assert_response :unauthorized
    end
  end
end
