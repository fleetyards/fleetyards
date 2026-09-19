# frozen_string_literal: true

require "test_helper"

module Inventories
  class TransferAuthorizerTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @other = create(:user)
      @inventory = create(:inventory, holder: @user)
    end

    test "a holder may withdraw from and deposit into their own inventory" do
      authorizer = TransferAuthorizer.new(@user)

      assert authorizer.may_withdraw_from?(@inventory)
      assert authorizer.may_deposit_into?(@inventory)
    end

    test "somebody else may do neither" do
      authorizer = TransferAuthorizer.new(@other)

      refute authorizer.may_withdraw_from?(@inventory)
      refute authorizer.may_deposit_into?(@inventory)
    end

    test "a fleet inventory answers to the privilege, not to membership alone" do
      fleet = create(:fleet)
      fleet_inventory = create(:fleet_inventory, fleet:)

      officer = create(:user)
      create(:fleet_membership, :accepted, :as_officer, fleet:, user: officer)

      plain = create(:user)
      create(:fleet_membership, :accepted, fleet:, user: plain)

      assert TransferAuthorizer.new(officer).may_deposit_into?(fleet_inventory)
      refute TransferAuthorizer.new(plain).may_deposit_into?(fleet_inventory),
        "a member without fleet:inventories:update must not be able to deposit"
    end

    test "a pending membership grants nothing" do
      fleet = create(:fleet)
      fleet_inventory = create(:fleet_inventory, fleet:)
      invitee = create(:user)
      create(:fleet_membership, :invited, :as_officer, fleet:, user: invitee)

      refute TransferAuthorizer.new(invitee).may_deposit_into?(fleet_inventory)
    end

    test "may_answer_for? is the same question asked of a party" do
      fleet = create(:fleet)
      officer = create(:user)
      create(:fleet_membership, :accepted, :as_officer, fleet:, user: officer)

      assert TransferAuthorizer.new(@user).may_answer_for?(@user)
      refute TransferAuthorizer.new(@other).may_answer_for?(@user)
      assert TransferAuthorizer.new(officer).may_answer_for?(fleet)
      refute TransferAuthorizer.new(@other).may_answer_for?(fleet)
    end

    test "nobody is authorized without a user" do
      authorizer = TransferAuthorizer.new(nil)

      refute authorizer.may_withdraw_from?(@inventory)
      refute authorizer.may_deposit_into?(@inventory)
      refute authorizer.may_answer_for?(@user)
      assert_empty authorizer.sendable_parties
    end

    test "sendable_parties is you plus the fleets you may move stock in" do
      fleet = create(:fleet)
      create(:fleet_membership, :accepted, :as_officer, fleet:, user: @user)

      other_fleet = create(:fleet)
      create(:fleet_membership, :accepted, fleet: other_fleet, user: @user)

      parties = TransferAuthorizer.new(@user).sendable_parties

      assert_includes parties, @user
      assert_includes parties, fleet
      refute_includes parties, other_fleet
    end

    # Privileges and visibility are separate gates: holding the write privilege
    # for a fleet says nothing about whether this is a store you may see. A
    # transfer names its two ends by id, so this is the one way into an
    # officers-only inventory that does not go through a lookup.
    test "an officers-only inventory is not an end a plain writer can name" do
      fleet = create(:fleet)
      closed = create(:fleet_inventory, :officers_only, fleet:)
      open_store = create(:fleet_inventory, fleet:)

      role = create(:fleet_role, fleet:, name: "Quartermaster",
        resource_access: ["fleet:inventories:read", "fleet:inventories:update"])
      writer = create(:user)
      create(:fleet_membership, :accepted, fleet:, user: writer, fleet_role: role)

      authorizer = TransferAuthorizer.new(writer)

      assert authorizer.may_deposit_into?(open_store)
      refute authorizer.may_withdraw_from?(closed)
      refute authorizer.may_deposit_into?(closed)
    end

    test "an officer still moves stock through an officers-only inventory" do
      fleet = create(:fleet)
      closed = create(:fleet_inventory, :officers_only, fleet:)
      officer = create(:user)
      create(:fleet_membership, :accepted, :as_officer, fleet:, user: officer)

      authorizer = TransferAuthorizer.new(officer)

      assert authorizer.may_withdraw_from?(closed)
      assert authorizer.may_deposit_into?(closed)
    end
  end
end
