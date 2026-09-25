# frozen_string_literal: true

require "test_helper"

class Relationships::NotifierTest < ActiveSupport::TestCase
  setup do
    @sender = create(:user)
    @target = create(:user)
  end

  def request(from: @sender, to: @target)
    Relationships::Requester.new(Friendship, requester: from, addressee: to).tap(&:call)
  end

  def notifications_for(user, type: nil)
    scope = Notification.where(user: user)
    scope = scope.where(notification_type: type) if type
    scope
  end

  test "a request tells the person who was asked, and nobody else" do
    request

    assert_equal 1, notifications_for(@target, type: :friend_request_received).count
    assert_empty notifications_for(@sender)
  end

  test "the notification names the sender and points at the list it is answered on" do
    request

    notification = notifications_for(@target).sole

    assert_includes notification.title, @sender.username
    assert_equal "/settings/friends/incoming/", notification.link
    assert_equal Friendship.between(@sender, @target), notification.record
  end

  # The other half of the same rule: an acceptance is news about a relationship
  # that now exists, and the accepted list is the one holding it.
  test "an acceptance points at the friends themselves" do
    friendship = request.relationship
    Relationships::Answerer.new(friendship, actor: @target).accept(@target)

    assert_equal "/settings/friends/", notifications_for(@sender, type: :friend_request_accepted).sole.link
  end

  test "accepting tells the person who asked" do
    friendship = request.relationship
    Relationships::Answerer.new(friendship, actor: @target).accept(@target)

    assert_equal 1, notifications_for(@sender, type: :friend_request_accepted).count
    assert_includes notifications_for(@sender).sole.title, @target.username
  end

  test "a crossing request tells the other side it was accepted" do
    create(:friendship, requester: @target, addressee: @sender)

    request

    assert_equal 1, notifications_for(@target, type: :friend_request_accepted).count
  end

  test "declining tells nobody" do
    friendship = request.relationship
    Notification.delete_all
    Relationships::Answerer.new(friendship, actor: @target).decline(@target)

    assert_empty Notification.all
  end

  test "ignoring tells nobody" do
    friendship = request.relationship
    Notification.delete_all
    Relationships::Answerer.new(friendship, actor: @target).ignore(@target)

    assert_empty Notification.all
  end

  # The one that would give the whole thing away.
  test "a request absorbed by an ignore reaches nobody" do
    create(:friendship, :ignored, requester: @sender, addressee: @target)

    assert request.success?
    assert_empty Notification.all
  end

  test "asking twice does not notify twice" do
    request
    request

    assert_equal 1, notifications_for(@target).count
  end

  test "reopening a declined request notifies again, because it is a new ask" do
    create(:friendship, :declined, requester: @sender, addressee: @target)

    request

    assert_equal 1, notifications_for(@target, type: :friend_request_received).count
  end

  # Existing-row transitions are serialized, so a re-request that loses the race
  # finds the row already pending and resends rather than reopening it a second
  # time.
  test "reopening a declined request twice notifies once" do
    create(:friendship, :declined, requester: @sender, addressee: @target)

    request
    request

    assert_equal 1, notifications_for(@target, type: :friend_request_received).count
  end

  test "an alliance request reaches only the members who could answer it" do
    admin = create(:user)
    officer = create(:user)
    member = create(:user)
    fleet = create(:fleet, admins: [admin], officers: [officer], members: [member])
    other_fleet = create(:fleet, created_by: create(:user).id)

    Relationships::Requester.new(FleetAlliance, requester: other_fleet, addressee: fleet).call

    assert_equal 1, notifications_for(admin, type: :fleet_ally_request_received).count
    assert_empty notifications_for(officer)
    assert_empty notifications_for(member)
  end

  test "an alliance notification names the other fleet and points at the allies settings" do
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    other_fleet = create(:fleet, created_by: create(:user).id)

    Relationships::Requester.new(FleetAlliance, requester: other_fleet, addressee: fleet).call

    notification = notifications_for(admin).sole

    assert_includes notification.title, other_fleet.name
    assert_includes notification.title, fleet.name
    assert_equal "/fleets/#{fleet.slug}/settings/allies/incoming/", notification.link
  end
end
