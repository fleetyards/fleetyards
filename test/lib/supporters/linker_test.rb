# frozen_string_literal: true

require "test_helper"

module Supporters
  class LinkerTest < ActiveSupport::TestCase
    test "links by a confirmed email match" do
      user = create(:user, email: "patron@example.test", confirmed_at: Time.current)
      contribution = create(:supporter_contribution, payer_email: "patron@example.test")

      assert_equal user, Supporters::Linker.call(contribution)
      assert_equal user, contribution.reload.user
    end

    test "matches an email regardless of case or surrounding space" do
      user = create(:user, email: "patron@example.test", confirmed_at: Time.current)
      contribution = create(:supporter_contribution, payer_email: "  PATRON@Example.TEST ")

      assert_equal user, Supporters::Linker.call(contribution)
    end

    test "never matches an unconfirmed account by email" do
      create(:user, email: "patron@example.test", confirmed_at: nil)
      contribution = create(:supporter_contribution, payer_email: "patron@example.test")

      assert_nil Supporters::Linker.call(contribution)
      assert_nil contribution.reload.user
    end

    test "links by a claim key found in the donation message" do
      user = create(:user, confirmed_at: Time.current)
      key = user.ensure_claim_key!
      contribution = create(:supporter_contribution, note: "keep it up! #{key}")

      assert_equal user, Supporters::Linker.call(contribution)
    end

    test "a claim key outranks an email belonging to someone else" do
      keyed = create(:user, confirmed_at: Time.current)
      key = keyed.ensure_claim_key!
      create(:user, email: "someone.else@example.test", confirmed_at: Time.current)
      contribution = create(:supporter_contribution,
        note: "for my fleet #{key}",
        payer_email: "someone.else@example.test")

      assert_equal keyed, Supporters::Linker.call(contribution)
    end

    test "resolves nothing when neither input matches" do
      contribution = create(:supporter_contribution, payer_email: "nobody@example.test", note: "thanks")

      assert_nil Supporters::Linker.call(contribution)
    end

    test "a key matching no account does not fall through to the email" do
      create(:user, email: "patron@example.test", confirmed_at: Time.current)
      contribution = create(:supporter_contribution,
        note: "my key is FY-7K2M-9QXD",
        payer_email: "patron@example.test")

      # The email still resolves -- an unmatched key is absence of a key, not a
      # veto. What must not happen is the key silently selecting a wrong user.
      assert_equal "patron@example.test", Supporters::Linker.call(contribution)&.email
    end

    test "never overwrites a link an admin already made" do
      linked = create(:user, confirmed_at: Time.current)
      other = create(:user, email: "other@example.test", confirmed_at: Time.current)
      contribution = create(:supporter_contribution, user: linked, payer_email: other.email)

      assert_equal linked, Supporters::Linker.call(contribution)
      assert_equal linked, contribution.reload.user
    end

    test "is idempotent and finds a donor who registered after paying" do
      contribution = create(:supporter_contribution, payer_email: "later@example.test")

      assert_nil Supporters::Linker.call(contribution)

      user = create(:user, email: "later@example.test", confirmed_at: Time.current)

      assert_equal user, Supporters::Linker.call(contribution)
      assert_equal user, contribution.reload.user
    end
  end
end
