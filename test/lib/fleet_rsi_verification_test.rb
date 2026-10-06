# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class FleetRsiVerificationTest < ActiveSupport::TestCase
  setup do
    @manager = create(:user)
    @fleet = create(:fleet, created_by: @manager.id, rsi_sid: "TEST")
    @fleet.generate_rsi_verification_token!
  end

  def stub_org_page(status: 200, symbol: "TEST", manifesto: "")
    body = format(Rails.root.join("test/fixtures/rsi/org_page.html").read, intro: "", manifesto:)
      .sub('<span class="symbol">TEST</span>', %(<span class="symbol">#{symbol}</span>))

    stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST").to_return(status:, body:)
  end

  def verify(fleet = @fleet)
    FleetRsiVerification.new(fleet).run
  end

  test "the token on the org page verifies the fleet" do
    stub_org_page(manifesto: @fleet.rsi_verification_token)

    assert_equal :verified, verify

    @fleet.reload
    assert @fleet.rsi_verified?
    assert_equal "TEST", @fleet.rsi_verified_sid
    assert_equal "TEST", @fleet.public_rsi_sid
  end

  test "a fleet that verifies has its RSI org synced straight away" do
    stub_org_page(manifesto: @fleet.rsi_verification_token)

    assert_difference -> { FleetRsiSyncJob.jobs.size }, 1 do
      verify
    end
    assert_equal [@fleet.id], FleetRsiSyncJob.jobs.last["args"]
  end

  test "a check that does not verify syncs nothing" do
    stub_org_page

    assert_no_difference -> { FleetRsiSyncJob.jobs.size } do
      verify
    end
  end

  test "a page RSI refuses to serve fails the check" do
    stub_org_page(status: 403)

    assert_equal :failed, verify
    assert @fleet.reload.rsi_verification_failed?
  end

  test "a page without the token leaves the fleet unverified" do
    stub_org_page

    assert_equal :token_missing, verify
    assert_not @fleet.reload.rsi_verified?
    assert @fleet.rsi_verification_token_missing?
  end

  test "a page for a different org does not count" do
    stub_org_page(symbol: "OTHER", manifesto: @fleet.rsi_verification_token)

    assert_equal :symbol_mismatch, verify
    assert_not @fleet.reload.rsi_verified?
  end

  test "an org RSI does not know is reported as not found" do
    stub_org_page(status: 404)

    assert_equal :not_found, verify
  end

  test "a fleet without a token cannot be checked" do
    @fleet.update!(rsi_verification_token: nil)

    assert_equal :failed, verify
  end

  test "the latest proof takes the SID from the fleet that held it" do
    holder_manager = create(:user)
    holder = create(:fleet, created_by: holder_manager.id, rsi_sid: "TEST")
    holder.generate_rsi_verification_token!
    stub_org_page(manifesto: holder.rsi_verification_token)
    verify(holder)

    stub_org_page(manifesto: @fleet.rsi_verification_token)

    assert_difference -> { Notification.where(user: holder_manager, notification_type: :fleet_rsi_verification_lost).count }, 1 do
      verify
    end

    assert @fleet.reload.rsi_verified?
    assert_not holder.reload.rsi_verified?
    assert_nil holder.public_rsi_sid
  end

  test "an admin confirming the fleet verifies it without asking RSI" do
    assert_difference -> { FleetRsiSyncJob.jobs.size }, 1 do
      assert_equal :verified, FleetRsiVerification.new(@fleet).confirm!
    end

    assert @fleet.reload.rsi_verified?
    assert_equal "TEST", @fleet.rsi_verified_sid
  end

  test "an admin confirming the fleet takes the SID from the fleet that held it" do
    holder_manager = create(:user)
    holder = create(:fleet, :rsi_verified, created_by: holder_manager.id, rsi_sid: "TEST")

    assert_difference -> { Notification.where(user: holder_manager, notification_type: :fleet_rsi_verification_lost).count }, 1 do
      FleetRsiVerification.new(@fleet).confirm!
    end

    assert @fleet.reload.rsi_verified?
    assert_not holder.reload.rsi_verified?
  end

  test "an answer about a SID the fleet has since changed is dropped" do
    body = format(Rails.root.join("test/fixtures/rsi/org_page.html").read, intro: "", manifesto: @fleet.rsi_verification_token)
    stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST").to_return do
      Fleet.where(id: @fleet.id).update_all(rsi_sid: "OTHER") # rubocop:disable Rails/SkipsModelValidations
      {status: 200, body:}
    end

    assert_nil verify
    assert_not @fleet.reload.rsi_verified?
  end

  test "a check overtaken by a new token does not stay pending" do
    @fleet.update_columns(rsi_verification_status: :pending) # rubocop:disable Rails/SkipsModelValidations
    body = format(Rails.root.join("test/fixtures/rsi/org_page.html").read, intro: "", manifesto: @fleet.rsi_verification_token)
    stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST").to_return do
      @fleet.class.find(@fleet.id).generate_rsi_verification_token!
      {status: 200, body:}
    end

    assert_nil verify
    assert_nil @fleet.reload.rsi_verification_status
  end

  test "a manager who cannot be told does not undo the takeover" do
    holder = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")
    holder.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: "TEST") # rubocop:disable Rails/SkipsModelValidations
    stub_org_page(manifesto: @fleet.rsi_verification_token)

    Notification.singleton_class.alias_method(:original_notify!, :notify!)
    Notification.define_singleton_method(:notify!) { |**| raise "delivery failed" }
    begin
      assert_equal :verified, verify
    ensure
      Notification.singleton_class.alias_method(:notify!, :original_notify!)
      Notification.singleton_class.remove_method(:original_notify!)
    end

    assert @fleet.reload.rsi_verified?
    assert @fleet.rsi_verification_verified?
    assert_not holder.reload.rsi_verified?
  end

  test "an older check does not overwrite a newer one" do
    @fleet.update_columns(rsi_verification_checked_at: 2.minutes.ago.floor(6)) # rubocop:disable Rails/SkipsModelValidations
    older = FleetRsiVerification.new(@fleet.reload)
    @fleet.update_columns(rsi_verification_checked_at: Time.current.floor(6), rsi_verification_status: :verified) # rubocop:disable Rails/SkipsModelValidations
    stub_org_page

    assert_nil older.run
    assert @fleet.reload.rsi_verification_verified?
  end

  test "a check that outlives an admin revoke leaves the fleet revoked" do
    body = format(Rails.root.join("test/fixtures/rsi/org_page.html").read, intro: "", manifesto: @fleet.rsi_verification_token)
    stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST").to_return do
      Fleet.find(@fleet.id).revoke_rsi_verification!
      {status: 200, body:}
    end

    assert_nil verify
    assert_not @fleet.reload.rsi_verified?
  end
end
