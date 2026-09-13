# frozen_string_literal: true

require "test_helper"

# The handshake both `Friendship` and `FleetAlliance` get from the concern.
# Exercised through `Friendship` unless a case is specifically about fleets.
class PartyRelationshipTest < ActiveSupport::TestCase
  test "starts pending" do
    assert create(:friendship).pending?
  end

  test "each answer moves it and stamps its own timestamp" do
    {accept: %i[accepted accepted_at], decline: %i[declined declined_at], ignore: %i[ignored ignored_at]}
      .each do |event, (state, timestamp)|
      relationship = create(:friendship)

      assert relationship.public_send(:"#{event}!"), "#{event} did not transition"
      assert_equal state.to_s, relationship.reload.aasm_state
      assert_not_nil relationship.public_send(timestamp), "#{event} left #{timestamp} unset"
    end
  end

  test "an answered request cannot be answered again" do
    relationship = create(:friendship, :accepted)

    refute relationship.decline!
    assert relationship.reload.accepted?
  end

  # The decision the feature turns on: an ignore the sender can see is a decline
  # with worse manners.
  test "an ignored request still reads as pending to the requester" do
    relationship = create(:friendship, :ignored)

    assert_equal "pending", relationship.state_for(relationship.requester)
    assert_equal "ignored", relationship.state_for(relationship.addressee)
  end

  test "every other state reads the same to both parties" do
    %i[accepted declined].each do |state|
      relationship = create(:friendship, state)

      assert_equal state.to_s, relationship.state_for(relationship.requester)
      assert_equal state.to_s, relationship.state_for(relationship.addressee)
    end
  end

  test "a party is not its own friend" do
    user = create(:user)
    relationship = build(:friendship, requester: user, addressee: user)

    refute relationship.valid?
  end

  test "the database refuses a self-relationship even without validations" do
    user = create(:user)

    assert_raises(ActiveRecord::StatementInvalid) do
      build(:friendship, requester: user, addressee: user).save(validate: false)
    end
  end

  test "one row per unordered pair, in either direction" do
    one = create(:user)
    other = create(:user)
    create(:friendship, requester: one, addressee: other)

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:friendship, requester: other, addressee: one).save(validate: false)
    end
  end

  test "between finds the row from either end" do
    one = create(:user)
    other = create(:user)
    relationship = create(:friendship, requester: one, addressee: other)

    assert_equal relationship, Friendship.between(one, other)
    assert_equal relationship, Friendship.between(other, one)
  end

  test "between is nil for a party that has none" do
    assert_nil Friendship.between(create(:user), create(:user))
  end

  test "partner ids read over both columns and only for accepted rows" do
    user = create(:user)
    friend_who_asked = create(:user)
    friend_who_was_asked = create(:user)
    stranger = create(:user)

    create(:friendship, :accepted, requester: friend_who_asked, addressee: user)
    create(:friendship, :accepted, requester: user, addressee: friend_who_was_asked)
    create(:friendship, requester: stranger, addressee: user)

    assert_equal [friend_who_asked, friend_who_was_asked].map(&:id).sort, user.friends.pluck(:id).sort
  end

  test "friend_of? is symmetric and only true once accepted" do
    one = create(:user)
    other = create(:user)
    relationship = create(:friendship, requester: one, addressee: other)

    refute one.friend_of?(other)

    relationship.accept!

    assert one.reload.friend_of?(other)
    assert other.reload.friend_of?(one)
  end

  test "only the addressee may answer, only the requester may call it back" do
    relationship = create(:friendship)

    assert relationship.answerable_by?(relationship.addressee)
    refute relationship.answerable_by?(relationship.requester)
    assert relationship.cancellable_by?(relationship.requester)
    refute relationship.cancellable_by?(relationship.addressee)
  end

  test "an answered request is neither answerable nor cancellable" do
    relationship = create(:friendship, :accepted)

    refute relationship.answerable_by?(relationship.addressee)
    refute relationship.cancellable_by?(relationship.requester)
  end

  test "the cap counts only what is waiting for this party" do
    user = create(:user)
    create_list(:friendship, 2, addressee: user)
    create(:friendship, :accepted, addressee: user)
    create(:friendship, requester: user)

    assert_equal 2, Friendship.outstanding_for(user)
    refute Friendship.at_capacity?(user)
  end

  test "a fleet alliance is the same handshake" do
    one = create(:fleet)
    other = create(:fleet)
    alliance = create(:fleet_alliance, requester: one, addressee: other)

    assert alliance.pending?
    assert alliance.accept!
    assert one.reload.allied_with?(other)
    assert other.reload.allied_with?(one)
  end

  test "a discarded fleet is nobody's ally" do
    one = create(:fleet, created_by: create(:user).id)
    other = create(:fleet, created_by: create(:user).id)
    create(:fleet_alliance, :accepted, requester: one, addressee: other)

    other.discard

    refute one.reload.allied_with?(other.reload)
    assert_empty one.allies
  end
end
