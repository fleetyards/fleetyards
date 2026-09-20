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

    Flipper.enable(:online_status)
  end

  teardown do
    Flipper.disable(:online_status)
  end

  def presence_broadcasts_to(user)
    broadcasts(UserPresenceChannel.broadcasting_for(user))
  end

  def last_payload(stream)
    ActiveSupport::JSON.decode(broadcasts(stream).last)
  end

  def run_job(online: true)
    Presence::BroadcastTransitionJob.new.perform(@user.id, online)
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

  test "the user who opted out reads as offline to a co-member" do
    @user.update!(show_online_status: false)

    run_job

    refute last_payload(UserPresenceChannel.broadcasting_for(@co_member))["online"]
  end

  test "an admin sees the truth about a user who opted out" do
    admin_user = create(:admin_user)
    @user.update!(show_online_status: false)

    run_job

    assert last_payload(AdminPresenceChannel.broadcasting_for(admin_user))["online"]
  end

  test "the flag gates the roster fan-out but not the admin one" do
    Flipper.disable(:online_status)
    admin_user = create(:admin_user)

    assert_no_difference -> { presence_broadcasts_to(@co_member).size } do
      assert_difference -> { broadcasts(AdminPresenceChannel.broadcasting_for(admin_user)).size }, 1 do
        run_job
      end
    end
  end

  test "a user who no longer exists broadcasts nothing" do
    assert_nothing_raised do
      Presence::BroadcastTransitionJob.new.perform(SecureRandom.uuid, true)
    end
  end
end
