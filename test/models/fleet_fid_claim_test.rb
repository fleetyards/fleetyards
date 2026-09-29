# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

# == Schema Information
#
# Table name: fleet_fid_claims
#
#  id                  :uuid             not null, primary key
#  cancel_reason       :string
#  cancelled_at        :datetime
#  completed_at        :datetime
#  created_by          :uuid
#  ends_at             :datetime         not null
#  fid                 :string           not null
#  holder_new_fid      :string
#  holder_previous_fid :string
#  state               :string           default("open"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  claimant_id         :uuid             not null
#  holder_id           :uuid
#
# Indexes
#
#  index_fleet_fid_claims_on_claimant_id        (claimant_id)
#  index_fleet_fid_claims_on_holder_id          (holder_id)
#  index_fleet_fid_claims_on_open_fid           (fid) UNIQUE WHERE ((state)::text = 'open'::text)
#  index_fleet_fid_claims_on_state_and_ends_at  (state,ends_at)
#
# Foreign Keys
#
#  fk_rails_...  (claimant_id => fleets.id) ON DELETE => cascade
#  fk_rails_...  (holder_id => fleets.id) ON DELETE => nullify
#
class FleetFidClaimTest < ActiveSupport::TestCase
  setup do
    @claimant_manager = create(:user)
    @holder_manager = create(:user)
    @claimant = create(:fleet, :rsi_verified, fid: "TEST-1", rsi_sid: "TEST", created_by: @claimant_manager.id)
    @holder = create(:fleet, fid: "test", created_by: @holder_manager.id)
  end

  def notifications_for(user, type)
    Notification.where(user:, notification_type: type)
  end

  def open_claim
    FleetFidClaim.open_for!(@claimant, user: @claimant_manager)
  end

  test "a verified fleet can claim the FID another fleet holds" do
    assert_equal :claimable, FleetFidClaim.availability_for(@claimant)
  end

  test "availability explains why a fleet cannot claim" do
    assert_equal :unverified, FleetFidClaim.availability_for(@holder)

    free = create(:fleet, :rsi_verified, rsi_sid: "FREE")
    assert_equal :available, FleetFidClaim.availability_for(free)

    short = create(:fleet, :rsi_verified, rsi_sid: "AB")
    assert_equal :invalid, FleetFidClaim.availability_for(short)

    owner = create(:fleet, :rsi_verified, fid: "own", rsi_sid: "OWN")
    assert_equal :held, FleetFidClaim.availability_for(owner)

    open_claim
    assert_equal :pending, FleetFidClaim.availability_for(@claimant)
  end

  test "opening a claim gives the holder the grace period and tells its managers" do
    claim = nil

    assert_difference -> { notifications_for(@holder_manager, :fleet_fid_claim_opened).count }, 1 do
      claim = open_claim
    end

    assert claim.open?
    assert_equal "TEST", claim.fid
    assert_equal @holder, claim.holder
    assert_in_delta FleetFidClaim::GRACE_PERIOD.from_now, claim.ends_at, 5.seconds
    assert_empty notifications_for(@claimant_manager, :fleet_fid_claim_opened)

    notification = notifications_for(@holder_manager, :fleet_fid_claim_opened).last
    assert_includes notification.body, I18n.l(claim.ends_at.to_date, format: :long)
    assert_equal "/fleets/#{@holder.slug}/settings/rsi/", notification.link
  end

  test "a fleet that cannot claim opens nothing" do
    @claimant.revoke_rsi_verification!

    assert_nil open_claim
    assert_equal 0, FleetFidClaim.count
  end

  test "only one claim can be open per FID" do
    open_claim

    assert_nil open_claim
    assert_equal 1, FleetFidClaim.count
  end

  test "a claimed FID is reserved for the claimant" do
    open_claim
    @holder.update!(fid: "elsewhere")

    squatter = build(:fleet, fid: "TEST")
    assert_not squatter.valid?
    assert_includes squatter.errors.details[:fid], {error: :reserved}

    @holder.fid = "test"
    assert_not @holder.valid?

    @claimant.fid = "TEST"
    assert @claimant.valid?
  end

  test "the holder may change the case of the FID it holds" do
    open_claim

    @holder.fid = "TEST"
    assert @holder.valid?
  end

  test "a due claim renames the holder and hands the FID to the claimant" do
    create(:fleet, fid: "TEST-2")
    claim = open_claim
    claim.update!(ends_at: 1.minute.ago)

    assert_difference -> { notifications_for(@holder_manager, :fleet_fid_claim_completed).count }, 1 do
      assert_difference -> { notifications_for(@claimant_manager, :fleet_fid_claim_completed).count }, 1 do
        assert_equal :completed, claim.complete!
      end
    end

    assert_equal "TEST-3", @holder.reload.fid
    assert_equal "test-3", @holder.slug
    assert_equal "TEST", @claimant.reload.fid
    assert_equal "test", @claimant.slug

    claim.reload
    assert claim.completed?
    assert_equal "test", claim.holder_previous_fid
    assert_equal "TEST-3", claim.holder_new_fid

    notification = notifications_for(@holder_manager, :fleet_fid_claim_completed).last
    assert_includes notification.title, "TEST-3"
    assert_equal "/fleets/test-3/settings/rsi/", notification.link
  end

  test "a claim is not completed before its grace period ends" do
    claim = open_claim

    assert_nil claim.complete!
    assert claim.reload.open?
    assert_equal "test", @holder.reload.fid
  end

  test "a holder that left the FID loses nothing when the claim completes" do
    claim = open_claim
    @holder.update!(fid: "elsewhere")
    claim.update!(ends_at: 1.minute.ago)

    assert_equal :completed, claim.complete!

    assert_equal "elsewhere", @holder.reload.fid
    assert_equal "TEST", @claimant.reload.fid
    assert_nil claim.reload.holder_new_fid
    assert_empty notifications_for(@holder_manager, :fleet_fid_claim_completed)
  end

  test "a fleet that took the FID after the claim opened gets its own notice" do
    claim = open_claim
    @holder.update!(fid: "elsewhere")
    newcomer_manager = create(:user)
    newcomer = create(:fleet, fid: "other", created_by: newcomer_manager.id)
    # Past the reservation, the way a restore or a lost race would leave it.
    newcomer.update_columns(fid: "test", normalized_fid: "test", slug: "test") # rubocop:disable Rails/SkipsModelValidations
    claim.update!(ends_at: 1.minute.ago)

    assert_difference -> { notifications_for(newcomer_manager, :fleet_fid_claim_opened).count }, 1 do
      assert_equal :restarted, claim.complete!
    end

    claim.reload
    assert claim.open?
    assert_equal newcomer, claim.holder
    assert_in_delta FleetFidClaim::GRACE_PERIOD.from_now, claim.ends_at, 5.seconds
    assert_equal "test", newcomer.reload.fid
  end

  test "the sweep completes every due claim" do
    claim = open_claim
    claim.update!(ends_at: 1.minute.ago)

    FleetFidClaimsCompleteJob.new.perform

    assert claim.reload.completed?
  end

  test "the holder proving the SID itself cancels the claim" do
    claim = open_claim
    @holder.update!(rsi_sid: "TEST")
    @holder.generate_rsi_verification_token!

    body = format(Rails.root.join("test/fixtures/rsi/org_page.html").read, intro: "", manifesto: @holder.reload.rsi_verification_token)
    stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST").to_return(status: 200, body:)

    assert_difference -> { notifications_for(@claimant_manager, :fleet_fid_claim_cancelled).count }, 1 do
      assert_equal :verified, FleetRsiVerification.new(@holder).run
    end

    claim.reload
    assert claim.cancelled?
    assert claim.cancelled_by_holder_verified?
    assert_equal "test", @holder.reload.fid

    holder_notice = notifications_for(@holder_manager, :fleet_fid_claim_cancelled).last
    assert_equal I18n.t("notifications.fleet_fid_claim_cancelled.holder_holder_verified.title", fleet: @holder.name, fid: "TEST"), holder_notice.title
  end

  test "an admin revoke cancels the claimant's claim" do
    claim = open_claim

    @claimant.revoke_rsi_verification!

    assert claim.reload.cancelled_by_claimant_unverified?
  end

  test "discarding the claimant cancels its claim" do
    claim = open_claim

    @claimant.discard

    assert claim.reload.cancelled_by_claimant_unverified?
  end

  test "completing re-checks the claimant's verification" do
    claim = open_claim
    claim.update!(ends_at: 1.minute.ago)
    # Past the callbacks, the way a lost race would leave it.
    @claimant.update_columns(rsi_verified_at: nil, rsi_verified_sid: nil) # rubocop:disable Rails/SkipsModelValidations

    assert_equal :cancelled, claim.complete!

    assert claim.reload.cancelled_by_claimant_unverified?
    assert_equal "test", @holder.reload.fid
  end

  test "a claimant that withdraws is not told about it" do
    claim = open_claim

    assert_difference -> { notifications_for(@holder_manager, :fleet_fid_claim_cancelled).count }, 1 do
      claim.cancel!(:withdrawn)
    end

    assert_empty notifications_for(@claimant_manager, :fleet_fid_claim_cancelled)
    assert_not claim.cancel!(:admin)
  end

  test "next_free_fid skips suffixes kept fleets already use" do
    create(:fleet, fid: "abc-1")
    create(:fleet, fid: "ABC-2")
    create(:fleet, fid: "ABC-4")

    assert_equal "ABC-3", Fleet.next_free_fid("abc")
  end
end
