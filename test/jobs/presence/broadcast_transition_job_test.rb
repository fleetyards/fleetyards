# frozen_string_literal: true

require "test_helper"

# Who is told that somebody came online. The audience is exactly the set of
# people the user has an accepted relationship with — co-members of a fleet they
# joined, and friends in either direction of the pair — plus the admins, who see
# it unredacted.
class Presence::BroadcastTransitionJobTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @user = create(:user)
    @co_member = create(:user)
    @fleet = create(:fleet, officers: [@user], members: [@co_member])

    UserPresence.reset!
    connect_user
  end

  teardown do
    UserPresence.reset!
  end

  def presence_broadcasts_to(user)
    broadcasts(UserPresenceChannel.broadcasting_for(user))
  end

  def last_payload(stream)
    ActiveSupport::JSON.decode(broadcasts(stream).last)
  end

  # The job reads the store rather than taking the value, so a test that wants
  # to be broadcast as online has to be online.
  def connect_user
    UserPresence.connect(@user.id, "tab-1")
  end

  def run_job(reason: Presence::BroadcastTransitionJob::REASON_CONNECTION)
    Presence::BroadcastTransitionJob.new.perform(@user.id, reason)
  end

  test "a co-member is told" do
    assert_difference -> { presence_broadcasts_to(@co_member).size }, 1 do
      run_job
    end
  end

  test "a friend is told, whichever end of the pair they are" do
    requester = create(:user)
    addressee = create(:user)
    create(:friendship, :accepted, requester: requester, addressee: @user)
    create(:friendship, :accepted, requester: @user, addressee: addressee)

    [requester, addressee].each do |friend|
      assert_difference -> { presence_broadcasts_to(friend).size }, 1,
        "a friend was not told" do
        run_job
      end
    end
  end

  test "a stranger is never told" do
    stranger = create(:user)

    assert_no_difference -> { presence_broadcasts_to(stranger).size } do
      run_job
    end
  end

  test "an unanswered, declined or ignored friendship leaks nothing" do
    %i[pending declined ignored].each do |state|
      other = create(:user)
      if state == :pending
        create(:friendship, requester: other, addressee: @user)
      else
        create(:friendship, state, requester: other, addressee: @user)
      end

      assert_no_difference -> { presence_broadcasts_to(other).size },
        "a #{state} friendship leaked presence" do
        run_job
      end
    end
  end

  test "an invited or requested membership is not a co-membership" do
    invited = create(:user)
    create(:fleet_membership, fleet: @fleet, user: invited, aasm_state: "invited")

    assert_no_difference -> { presence_broadcasts_to(invited).size } do
      run_job
    end
  end

  # Emitting `online: false` on every connect and disconnect would leak the
  # timing of both, which is the thing the switch exists to hide.
  test "a connection change reaches no peer of somebody who opted out" do
    @user.update!(show_online_status: false)

    assert_no_difference -> { presence_broadcasts_to(@co_member).size } do
      run_job
    end
  end

  test "the switch itself sends one correction, and it reads offline" do
    @user.update!(show_online_status: false)

    assert_difference -> { presence_broadcasts_to(@co_member).size }, 1 do
      run_job(reason: Presence::BroadcastTransitionJob::REASON_PREFERENCE)
    end

    refute last_payload(UserPresenceChannel.broadcasting_for(@co_member))["online"]
  end

  test "an admin sees the truth about a user who opted out" do
    admin_user = create(:admin_user)
    @user.update!(show_online_status: false)

    run_job

    assert last_payload(AdminPresenceChannel.broadcasting_for(admin_user))["online"]
  end

  test "one unreachable recipient does not stop the rest, and the job still fails" do
    other = create(:user)
    create(:fleet_membership, fleet: @fleet, user: other, aasm_state: "accepted")

    UserPresenceChannel.stubs(:broadcast_to).raises(RuntimeError, "cable down")
    AdminPresenceChannel.stubs(:broadcast_to)

    error = assert_raises(Presence::BroadcastTransitionJob::BroadcastFailed) { run_job }

    assert_match(/2 recipient\(s\) not reached/, error.message)
  end

  test "a user who no longer exists broadcasts nothing" do
    assert_nothing_raised do
      Presence::BroadcastTransitionJob.new.perform(SecureRandom.uuid)
    end
  end

  # A retry of a job that partially failed can land after the transition that
  # superseded it, so the message has to say what is true when it is sent
  # rather than replaying what was true when it was queued.
  test "it publishes the state at send time, not the one it was queued for" do
    UserPresence.reset!

    run_job

    refute last_payload(UserPresenceChannel.broadcasting_for(@co_member))["online"]
  end
end
