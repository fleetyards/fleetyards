# frozen_string_literal: true

require "test_helper"

class Relationships::AnswererTest < ActiveSupport::TestCase
  setup do
    @requester = create(:user)
    @addressee = create(:user)
    @relationship = create(:friendship, requester: @requester, addressee: @addressee)
  end

  def answerer(relationship = @relationship, actor: @addressee)
    Relationships::Answerer.new(relationship, actor:)
  end

  test "the addressee can accept, decline or ignore" do
    {accept: :accepted?, decline: :declined?, ignore: :ignored?}.each do |answer, state|
      relationship = create(:friendship)
      service = answerer(relationship, actor: relationship.addressee)

      assert service.public_send(answer, relationship.addressee), service.errors.full_messages.to_sentence
      assert relationship.reload.public_send(state)
    end
  end

  test "the requester cannot answer their own request" do
    service = answerer(actor: @requester)

    refute service.accept(@requester)
    assert_includes service.errors.details[:base].pluck(:error), :forbidden
    assert @relationship.reload.pending?
  end

  test "a stranger cannot answer" do
    stranger = create(:user)

    refute answerer(actor: stranger).accept(stranger)
    assert @relationship.reload.pending?
  end

  test "an already answered request cannot be answered again" do
    @relationship.accept!

    service = answerer
    refute service.decline(@addressee)
    assert_includes service.errors.details[:base].pluck(:error), :forbidden
    assert @relationship.reload.accepted?
  end

  test "the requester can call a pending request back, and the row goes" do
    assert answerer(actor: @requester).cancel(@requester)
    assert_nil Friendship.find_by(id: @relationship.id)
  end

  test "the addressee cannot cancel a request they were sent" do
    refute answerer.cancel(@addressee)
    assert @relationship.reload.pending?
  end

  test "either side can end an accepted friendship" do
    [@requester, @addressee].each do |party|
      relationship = create(:friendship, :accepted)
      other = (party == @requester) ? relationship.requester : relationship.addressee

      assert answerer(relationship, actor: other).end_relationship(other)
      assert_nil Friendship.find_by(id: relationship.id)
    end
  end

  test "ending needs an accepted relationship, not a pending one" do
    refute answerer(actor: @requester).end_relationship(@requester)
    assert @relationship.reload.pending?
  end

  test "a stranger cannot end somebody else's friendship" do
    relationship = create(:friendship, :accepted)
    stranger = create(:user)

    refute answerer(relationship, actor: stranger).end_relationship(stranger)
    assert relationship.reload.accepted?
  end

  # Cancelling has to answer the same way whether or not the other side ignored
  # it, and must not clear the ignore -- otherwise cancel-and-ask-again is a way
  # straight back into an inbox that turned you away.
  test "cancelling an ignored request succeeds and leaves it standing" do
    ignored = create(:friendship, :ignored)

    assert answerer(ignored, actor: ignored.requester).cancel(ignored.requester)
    assert ignored.reload.ignored?
    assert ignored.withdrawn?
  end

  # The row survives so that asking again still goes nowhere, and that is the
  # only reason. It must be gone from every list the sender reads, or the
  # withdrawal itself becomes the tell: a real one takes the row with it.
  test "a withdrawn request leaves the sender's pending list" do
    ignored = create(:friendship, :ignored)
    sender = ignored.requester

    assert_includes Friendship.in_state_for("pending", sender), ignored

    answerer(ignored, actor: sender).cancel(sender)

    assert_not_includes Friendship.in_state_for("pending", sender), ignored.reload
  end

  test "the recipient still sees a withdrawn request under ignored" do
    ignored = create(:friendship, :ignored)
    answerer(ignored, actor: ignored.requester).cancel(ignored.requester)

    assert_includes Friendship.in_state_for("ignored", ignored.addressee), ignored.reload
  end

  test "asking again after withdrawing an ignored request puts it back and tells nobody" do
    ignored = create(:friendship, :ignored)
    sender = ignored.requester
    target = ignored.addressee
    answerer(ignored, actor: sender).cancel(sender)
    Notification.delete_all

    requester = Relationships::Requester.new(Friendship, requester: sender, addressee: target).tap(&:call)

    assert requester.success?
    assert ignored.reload.ignored?
    refute ignored.withdrawn?
    assert_includes Friendship.in_state_for("pending", sender), ignored
    assert_empty Notification.all
  end

  test "asking again after cancelling an ignored request still goes nowhere" do
    ignored = create(:friendship, :ignored)
    sender = ignored.requester
    target = ignored.addressee
    answerer(ignored, actor: sender).cancel(sender)

    requester = Relationships::Requester.new(Friendship, requester: sender, addressee: target).tap(&:call)

    assert requester.success?
    assert ignored.reload.ignored?
    assert_equal 1, Friendship.where(requester: sender, addressee: target).count
  end

  test "cancelling answers identically whether or not it was ignored" do
    plain = create(:friendship)
    ignored = create(:friendship, :ignored)

    plain_result = answerer(plain, actor: plain.requester).cancel(plain.requester)
    ignored_result = answerer(ignored, actor: ignored.requester).cancel(ignored.requester)

    assert_equal plain_result, ignored_result
  end

  test "ending one makes the pair requestable again" do
    @relationship.accept!
    answerer(actor: @requester).end_relationship(@requester)

    requester = Relationships::Requester.new(Friendship, requester: @requester, addressee: @addressee).tap(&:call)

    assert requester.success?
    assert requester.relationship.pending?
  end
end
