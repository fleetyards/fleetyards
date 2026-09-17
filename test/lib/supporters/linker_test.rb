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

    # The only arm nobody asserts: signing into Patreon proves which account it
    # is, where a key can be mistyped into the wrong payment and an address can
    # be shared.
    test "links by a connected Patreon account" do
      user = create(:user, confirmed_at: Time.current)
      create(:omniauth_connection, user: user, provider: :patreon, uid: "patreon-user-1")
      contribution = create(:supporter_contribution, :patreon, patreon_user_id: "patreon-user-1")

      assert_equal user, Supporters::Linker.call(contribution)
    end

    test "a connected Patreon account outranks a key and an email" do
      connected = create(:user, confirmed_at: Time.current)
      create(:omniauth_connection, user: connected, provider: :patreon, uid: "patreon-user-1")

      keyed = create(:user, confirmed_at: Time.current)
      key = keyed.ensure_claim_key!
      create(:user, email: "someone.else@example.test", confirmed_at: Time.current)

      contribution = create(:supporter_contribution, :patreon,
        patreon_user_id: "patreon-user-1",
        note: "thanks #{key}",
        payer_email: "someone.else@example.test")

      assert_equal connected, Supporters::Linker.call(contribution)
    end

    test "another provider's connection with the same uid does not match" do
      user = create(:user, confirmed_at: Time.current)
      create(:omniauth_connection, user: user, provider: :discord, uid: "patreon-user-1")
      contribution = create(:supporter_contribution, :patreon, patreon_user_id: "patreon-user-1")

      assert_nil Supporters::Linker.call(contribution)
    end

    test "a contribution with no Patreon user id falls through to the other arms" do
      user = create(:user, email: "patron@example.test", confirmed_at: Time.current)
      contribution = create(:supporter_contribution, payer_email: "patron@example.test")

      assert_equal user, Supporters::Linker.call(contribution)
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

    test "records which rule produced the link" do
      connected = create(:user, confirmed_at: Time.current)
      create(:omniauth_connection, user: connected, provider: :patreon, uid: "patreon-user-1")
      patreon = create(:supporter_contribution, :patreon, patreon_user_id: "patreon-user-1")

      keyed = create(:user, confirmed_at: Time.current)
      by_key = create(:supporter_contribution, note: "thanks #{keyed.ensure_claim_key!}")

      create(:user, email: "patron@example.test", confirmed_at: Time.current)
      by_email = create(:supporter_contribution, payer_email: "patron@example.test")

      Supporters::Linker.call(patreon)
      Supporters::Linker.call(by_key)
      Supporters::Linker.call(by_email)

      assert_equal "patreon_account", patreon.reload.linked_via
      assert_equal "claim_key", by_key.reload.linked_via
      assert_equal "payer_email", by_email.reload.linked_via
    end

    test "names no rule when nothing resolved" do
      contribution = create(:supporter_contribution, payer_email: "nobody@example.test")

      assert_nil Supporters::Linker.call(contribution)
      assert_nil contribution.reload.linked_via
    end

    test "links by the claim key field without one in the message" do
      user = create(:user, confirmed_at: Time.current)
      contribution = create(:supporter_contribution, claim_key: user.ensure_claim_key!, note: "thanks")

      assert_equal user, Supporters::Linker.call(contribution)
      assert_equal "claim_key", contribution.reload.linked_via
    end

    # An admin reading a donation message decided what it says; the message
    # itself is only a guess at the same thing.
    test "the claim key field outranks one written in the message" do
      field = create(:user, confirmed_at: Time.current)
      message = create(:user, confirmed_at: Time.current)
      contribution = create(:supporter_contribution,
        claim_key: field.ensure_claim_key!,
        note: "thanks #{message.ensure_claim_key!}")

      assert_equal field, Supporters::Linker.call(contribution)
    end

    # The admin form's own rule, left where the linker can see it: a link nobody
    # derived is an admin's choice, and it outranks every arm here.
    test "leaves an admin's manual link and its rule alone" do
      linked = create(:user, confirmed_at: Time.current)
      other = create(:user, email: "other@example.test", confirmed_at: Time.current)
      contribution = create(:supporter_contribution, user: linked, payer_email: other.email)

      assert_equal linked, Supporters::Linker.call(contribution)
      assert_equal "manual", contribution.reload.linked_via
    end

    test "is idempotent and finds a donor who registered after paying" do
      contribution = create(:supporter_contribution, payer_email: "later@example.test")

      assert_nil Supporters::Linker.call(contribution)

      user = create(:user, email: "later@example.test", confirmed_at: Time.current)

      assert_equal user, Supporters::Linker.call(contribution)
      assert_equal user, contribution.reload.user
    end

    test "a linked contribution inherits the supporter's standing choice of fleet" do
      membership = create(:fleet_membership, :accepted)
      supporter = membership.user
      supporter.update!(confirmed_at: Time.current, supported_fleet: membership.fleet)
      contribution = create(:supporter_contribution, note: "thanks #{supporter.ensure_claim_key!}")

      Supporters::Linker.call(contribution)

      assert_equal membership.fleet_id, contribution.reload.fleet_id
    end

    # An admin who filled the field in was looking at this payment; a standing
    # choice is only ever a default.
    test "a fleet already on the contribution is not overwritten" do
      membership = create(:fleet_membership, :accepted)
      supporter = membership.user
      other = create(:fleet_membership, :accepted, user: supporter).fleet
      supporter.update!(confirmed_at: Time.current, supported_fleet: membership.fleet)
      contribution = create(:supporter_contribution, note: "thanks #{supporter.ensure_claim_key!}")
      contribution.update_column(:fleet_id, other.id)

      Supporters::Linker.call(contribution)

      assert_equal other.id, contribution.reload.fleet_id
    end

    test "a standing choice for a fleet the supporter has left is not stamped" do
      membership = create(:fleet_membership, :accepted)
      supporter = membership.user
      supporter.update!(confirmed_at: Time.current, supported_fleet: membership.fleet)
      contribution = create(:supporter_contribution, note: "thanks #{supporter.ensure_claim_key!}")
      membership.discard

      Supporters::Linker.call(contribution)

      assert_equal supporter.id, contribution.reload.user_id
      assert_nil contribution.fleet_id
    end

    test "with no standing choice a contribution inherits the primary fleet" do
      membership = create(:fleet_membership, :accepted, primary: true)
      supporter = membership.user
      supporter.update!(confirmed_at: Time.current)
      contribution = create(:supporter_contribution, note: "thanks #{supporter.ensure_claim_key!}")

      Supporters::Linker.call(contribution)

      assert_equal membership.fleet_id, contribution.reload.fleet_id
    end

    test "no standing choice and no primary fleet leaves the nomination empty" do
      supporter = create(:user, confirmed_at: Time.current)
      contribution = create(:supporter_contribution, note: "thanks #{supporter.ensure_claim_key!}")

      Supporters::Linker.call(contribution)

      assert_equal supporter.id, contribution.reload.user_id
      assert_nil contribution.fleet_id
    end
  end
end
