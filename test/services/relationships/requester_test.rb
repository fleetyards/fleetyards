# frozen_string_literal: true

require "test_helper"

# The four ways a request can meet a row that already exists, and the one it
# must never be able to tell apart from the others.
class Relationships::RequesterTest < ActiveSupport::TestCase
  setup do
    @sender = create(:user)
    @target = create(:user)
  end

  def request(from: @sender, to: @target)
    Relationships::Requester.new(Friendship, requester: from, addressee: to).tap(&:call)
  end

  test "creates a pending request when there is nothing between them" do
    requester = request

    assert requester.success?
    assert_equal :created, requester.outcome
    assert requester.relationship.pending?
    assert_equal @sender, requester.relationship.requester
  end

  test "asking somebody who already asked you accepts their request" do
    theirs = create(:friendship, requester: @target, addressee: @sender)

    requester = request

    assert requester.success?
    assert_equal :accepted, requester.outcome
    assert theirs.reload.accepted?
    assert_equal 1, Friendship.count
  end

  test "a request to somebody who ignored you is absorbed" do
    ignored = create(:friendship, :ignored, requester: @sender, addressee: @target)

    requester = request

    assert requester.success?
    assert_equal :created, requester.outcome
    assert ignored.reload.ignored?
    assert_equal 1, Friendship.count
  end

  # The absorbed case has to be indistinguishable from a fresh one, outcome and
  # rendered state alike, or the sender learns they were ignored.
  test "an absorbed request answers exactly as a fresh one does" do
    fresh = request(to: create(:user))

    create(:friendship, :ignored, requester: @sender, addressee: @target)
    absorbed = request

    assert_equal fresh.outcome, absorbed.outcome
    assert_equal fresh.success?, absorbed.success?
    assert_equal(
      fresh.relationship.state_for(@sender),
      absorbed.relationship.state_for(@sender)
    )
  end

  test "an ignored row is never turned into an acceptance by asking again" do
    create(:friendship, :ignored, requester: @target, addressee: @sender)

    requester = request

    assert requester.success?
    assert_equal :created, requester.outcome
    refute requester.relationship.accepted?
  end

  test "a declined request is reopened rather than duplicated" do
    declined = create(:friendship, :declined, requester: @sender, addressee: @target)

    requester = request

    assert requester.success?
    assert_equal :created, requester.outcome
    assert declined.reload.pending?
    assert_nil declined.declined_at
    assert_equal 1, Friendship.count
  end

  test "asking twice is not an error" do
    existing = request.relationship
    requester = request

    assert requester.success?
    assert_equal existing, requester.relationship
    assert_equal 1, Friendship.count
  end

  test "asking somebody who is already a friend is refused" do
    create(:friendship, :accepted, requester: @sender, addressee: @target)

    requester = request

    refute requester.success?
    assert_includes requester.errors.details[:base].pluck(:error), :already_related
  end

  test "you cannot befriend yourself" do
    requester = request(to: @sender)

    refute requester.success?
    assert_includes requester.errors.details[:base].pluck(:error), :not_to_self
  end

  test "a missing party is a refusal rather than a crash" do
    refute request(to: nil).success?
  end

  test "a full inbox refuses a new request" do
    create_list(:friendship, PartyRelationship::OUTSTANDING_LIMIT, addressee: @target)

    requester = request

    refute requester.success?
    assert_includes requester.errors.details[:base].pluck(:error), :at_capacity
  end

  # A cap refusal is about the addressee's inbox, and an ignored request never
  # reaches one. Consulting the cap first would make a full inbox the single
  # signal that told a sender they had been ignored.
  test "a full inbox does not unmask an ignore" do
    create(:friendship, :ignored, requester: @sender, addressee: @target)
    create_list(:friendship, PartyRelationship::OUTSTANDING_LIMIT, addressee: @target)

    assert request.success?
  end

  test "fleets use the same service" do
    one = create(:fleet, created_by: create(:user).id)
    other = create(:fleet, created_by: create(:user).id)

    requester = Relationships::Requester.new(FleetAlliance, requester: one, addressee: other).tap(&:call)

    assert requester.success?
    assert requester.relationship.pending?
  end
end
