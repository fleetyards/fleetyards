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

  test "ending one makes the pair requestable again" do
    @relationship.accept!
    answerer(actor: @requester).end_relationship(@requester)

    requester = Relationships::Requester.new(Friendship, requester: @requester, addressee: @addressee).tap(&:call)

    assert requester.success?
    assert requester.relationship.pending?
  end
end
