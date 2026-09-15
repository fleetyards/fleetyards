# frozen_string_literal: true

require "test_helper"

module Kofi
  class PaymentImporterTest < ActiveSupport::TestCase
    def payload(overrides = {})
      {
        "verification_token" => "token",
        "message_id" => "msg-1",
        "timestamp" => "2026-06-01T10:00:00Z",
        "type" => "Donation",
        "is_public" => "true",
        "from_name" => "Jo Example",
        "message" => "keep it up!",
        "amount" => "5.00",
        "url" => "https://ko-fi.com/x",
        "email" => "jo@example.test",
        "currency" => "EUR",
        "is_subscription_payment" => "false",
        "kofi_transaction_id" => "txn-1"
      }.merge(overrides)
    end

    test "records a donation with the donor's own details" do
      record = Kofi::PaymentImporter.call(payload)

      assert record.kofi?
      assert_equal "txn-1", record.kofi_transaction_id
      assert_equal "Jo Example", record.name
      assert_equal "jo@example.test", record.payer_email
      assert_equal "keep it up!", record.note
      assert_equal 500, record.amount_cents
      assert_equal "EUR", record.currency
      assert_equal Date.new(2026, 6, 1), record.started_at
    end

    test "converts a foreign currency into EUR and keeps the original" do
      ExchangeRateFetcher.stubs(:convert_cents).with(500, from: "USD", to: "EUR").returns(460)

      record = Kofi::PaymentImporter.call(payload("currency" => "USD"))

      assert_equal 460, record.amount_cents
      assert_equal "EUR", record.currency
      assert_equal 500, record.source_amount_cents
      assert_equal "USD", record.source_currency
    end

    test "honours the donor's public/private choice rather than assuming" do
      assert_not Kofi::PaymentImporter.call(payload).anonymous?
      assert Kofi::PaymentImporter.call(payload("is_public" => "false", "kofi_transaction_id" => "txn-2")).anonymous?
    end

    # Ko-fi notifies on payment and never on cancellation, so a recurring row
    # would have nothing to end it and would grant perks forever.
    test "a subscription payment is recorded as that month's contribution, not as recurring" do
      record = Kofi::PaymentImporter.call(payload("is_subscription_payment" => "true"))

      assert_not record.recurring?
      assert_nil record.ended_at
      assert_includes SupporterContribution.active_in(Date.new(2026, 6, 1), Date.new(2026, 6, 30)), record
      assert_not_includes SupporterContribution.active_in(Date.new(2026, 7, 1), Date.new(2026, 7, 31)), record
    end

    test "a replayed webhook updates the same row rather than duplicating it" do
      Kofi::PaymentImporter.call(payload)

      assert_difference -> { SupporterContribution.count }, 0 do
        Kofi::PaymentImporter.call(payload("from_name" => "Jo Renamed"))
      end

      assert_equal "Jo Renamed", SupporterContribution.find_by(kofi_transaction_id: "txn-1").name
    end

    test "links the donor by a claim key in their message" do
      user = create(:user, confirmed_at: Time.current)
      key = user.ensure_claim_key!

      record = Kofi::PaymentImporter.call(payload("message" => "for my fleet #{key}"))

      assert_equal user, record.reload.user
    end

    test "links the donor by their confirmed email when no key is given" do
      user = create(:user, email: "jo@example.test", confirmed_at: Time.current)

      assert_equal user, Kofi::PaymentImporter.call(payload).reload.user
    end

    test "ignores a payload carrying no money or no transaction id" do
      assert_nil Kofi::PaymentImporter.call(payload("amount" => "0.00", "kofi_transaction_id" => "txn-zero"))
      assert_nil Kofi::PaymentImporter.call(payload("amount" => "", "kofi_transaction_id" => "txn-blank"))
      assert_nil Kofi::PaymentImporter.call(payload("kofi_transaction_id" => nil))
      assert_equal 0, SupporterContribution.count
    end
  end
end
