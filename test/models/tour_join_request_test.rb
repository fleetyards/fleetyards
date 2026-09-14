# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: tour_join_requests
#
#  id            :uuid             not null, primary key
#  aasm_state    :string           default("pending"), not null
#  decided_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  decided_by_id :uuid
#  tour_id       :uuid             not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_tour_join_requests_on_decided_by_id          (decided_by_id)
#  index_tour_join_requests_on_pending_tour_and_user  (tour_id,user_id) UNIQUE WHERE ((aasm_state)::text = 'pending'::text)
#  index_tour_join_requests_on_tour_id                (tour_id)
#  index_tour_join_requests_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (decided_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (tour_id => tours.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class TourJoinRequestTest < ActiveSupport::TestCase
  setup do
    @organiser = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@organiser], members: [@member])

    @tour = create(:tour, fleet: @fleet, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
  end

  test "is pending to begin with" do
    assert_predicate create(:tour_join_request, tour: @tour, user: @member), :pending?
  end

  # There is no list a stranger could have found it in, so there is nobody to
  # ask -- the invite link is the only way onto a standalone tour.
  test "refuses a standalone tour" do
    standalone = create(:tour, created_by: @organiser)

    request = build(:tour_join_request, tour: standalone, user: @member)

    assert_not request.valid?
    assert_includes request.errors.attribute_names, :tour
  end

  test "refuses a tour that is no longer open" do
    @tour.update!(status: "cancelled", cancelled_at: Time.current)

    assert_not build(:tour_join_request, tour: @tour, user: @member).valid?
  end

  test "refuses somebody already on the tour" do
    create(:payout_participant, payout_ledger: @ledger, user: @member)

    assert_not build(:tour_join_request, tour: @tour, user: @member).valid?
  end

  test "refuses a second ask while the first is unanswered" do
    create(:tour_join_request, tour: @tour, user: @member)

    assert_not build(:tour_join_request, tour: @tour, user: @member).valid?
  end

  test "allows asking again once the first was answered" do
    create(:tour_join_request, :declined, tour: @tour, user: @member)

    assert_predicate build(:tour_join_request, tour: @tour, user: @member), :valid?
  end

  test "approving adds the asker to the ledger" do
    request = create(:tour_join_request, tour: @tour, user: @member)

    assert request.approve_by(@organiser)
    assert_predicate request.reload, :approved?
    assert_equal @organiser.id, request.decided_by_id
    assert_predicate request.decided_at, :present?
    assert @ledger.payout_participants.exists?(user_id: @member.id)
  end

  # The shares are frozen once the transfers are computed, so the participant
  # row cannot be written -- and the request must not say it was.
  test "approving answers false once the ledger is settled" do
    request = create(:tour_join_request, tour: @tour, user: @member)
    @ledger.settle!(@organiser)

    assert_not request.approve_by(@organiser)
    assert_predicate request.reload, :pending?
    assert_not @ledger.payout_participants.exists?(user_id: @member.id)
  end

  test "approving an answered request answers false" do
    request = create(:tour_join_request, :declined, tour: @tour, user: @member)

    assert_not request.approve_by(@organiser)
  end

  # The organiser, and anyone who could settle the tour, since they are the
  # same set that can answer it.
  test "asking tells whoever can answer" do
    officer = create(:user)
    create(:fleet_membership,
      fleet: @fleet,
      user: officer,
      fleet_role: @fleet.fleet_roles.ranked.second,
      aasm_state: :accepted)

    assert_difference "Notification.where(notification_type: 'tour_join_request_received').count", 2 do
      create(:tour_join_request, tour: @tour, user: @member)
    end

    notification = Notification.where(notification_type: "tour_join_request_received").find_by(user: @organiser)

    assert_includes notification.title, @member.username
    assert_equal "/fleets/#{@fleet.slug}/tours/#{@tour.slug}/", notification.link
  end

  # Their role carries no payout privilege, so there is nothing for them to do
  # with it.
  test "asking leaves an ordinary member out of it" do
    other = create(:user)
    create(:fleet_membership,
      fleet: @fleet,
      user: other,
      fleet_role: @fleet.default_member_role,
      aasm_state: :accepted)
    @fleet.default_member_role.update!(resource_access: [])

    create(:tour_join_request, tour: @tour, user: @member)

    assert_not Notification.where(notification_type: "tour_join_request_received", user: other).exists?
  end

  test "approving tells the asker" do
    request = create(:tour_join_request, tour: @tour, user: @member)

    assert_difference "Notification.where(notification_type: 'tour_join_request_accepted').count", 1 do
      request.approve_by(@organiser)
    end

    notification = Notification.find_by(notification_type: "tour_join_request_accepted")

    assert_equal @member.id, notification.user_id
    assert_includes notification.title, @tour.title
  end

  test "a refused approval tells nobody" do
    request = create(:tour_join_request, tour: @tour, user: @member)
    @ledger.settle!(@organiser)

    assert_no_difference "Notification.where(notification_type: 'tour_join_request_accepted').count" do
      assert_not request.approve_by(@organiser)
    end
  end

  # A decline is the organiser's answer to give in their own words rather than
  # a notification telling somebody they were turned down.
  test "declining tells nobody" do
    request = create(:tour_join_request, tour: @tour, user: @member)

    assert_no_difference "Notification.count" do
      request.decline_by(@organiser)
    end
  end

  test "declining leaves the ledger alone" do
    request = create(:tour_join_request, tour: @tour, user: @member)

    assert request.decline_by(@organiser)
    assert_predicate request.reload, :declined?
    assert_not @ledger.payout_participants.exists?(user_id: @member.id)
  end
end
