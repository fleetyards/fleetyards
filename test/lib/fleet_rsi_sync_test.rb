# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class FleetRsiSyncTest < ActiveSupport::TestCase
  PAGE_URL = "https://robertsspaceindustries.com/en/orgs/TEST"
  SEARCH_URL = "https://robertsspaceindustries.com/api/orgs/getOrgs"

  setup do
    @fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")
    @fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: "TEST", rsi_verification_status: :verified) # rubocop:disable Rails/SkipsModelValidations
  end

  def stub_page(status: 200)
    body = format(Rails.root.join("test/fixtures/rsi/org_page.html").read, intro: "", manifesto: "")
    stub_request(:get, PAGE_URL).to_return(status:, body:)
  end

  def stub_search(status: 200)
    stub_request(:post, SEARCH_URL).to_return(status:, body: Rails.root.join("test/fixtures/rsi/org_search.json").read)
  end

  def sync(fleet = @fleet)
    FleetRsiSync.new(fleet).run
  end

  test "the org page and the org search are copied onto the fleet" do
    stub_page
    stub_search

    assert_equal :synced, sync

    @fleet.reload
    assert_equal "social", @fleet.primary_activity
    assert_equal "security", @fleet.secondary_activity
    assert_equal "casual", @fleet.commitment
    assert_equal "en", @fleet.language
    assert @fleet.recruiting
    assert @fleet.roleplay
    assert_equal 24578, @fleet.rsi_member_count
    assert_not_nil @fleet.rsi_synced_at
  end

  test "an unverified fleet is not synced" do
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "OTHER")

    assert_equal :skipped, sync(fleet)
    assert_not_requested :get, %r{/orgs/}
  end

  test "a source that cannot be read leaves its columns as they were" do
    @fleet.update_columns(language: "de", recruiting: false, primary_activity: "piracy", rsi_member_count: 12) # rubocop:disable Rails/SkipsModelValidations
    stub_page
    stub_search(status: 500)

    assert_equal :synced, sync

    @fleet.reload
    assert_equal "social", @fleet.primary_activity
    assert_equal "de", @fleet.language
    assert_not @fleet.recruiting
    assert_equal 12, @fleet.rsi_member_count
  end

  test "neither source answering fails and keeps every column" do
    @fleet.update_columns(primary_activity: "piracy") # rubocop:disable Rails/SkipsModelValidations
    stub_page(status: 500)
    stub_search(status: 500)

    assert_equal :failed, sync
    assert_equal "piracy", @fleet.reload.primary_activity
    assert_nil @fleet.rsi_synced_at
    assert_not_nil @fleet.rsi_sync_attempted_at
  end

  test "a block writes none of the RSI columns" do
    stub_page
    stub_search(status: 403)

    assert_equal :blocked, sync
    assert_nil @fleet.reload.primary_activity
  end

  test "a sync that outlived a revoke writes nothing" do
    stub_page
    stub_search
    stale = Fleet.find(@fleet.id)
    @fleet.revoke_rsi_verification!

    assert_equal :stale, FleetRsiSync.new(stale).send(:write, "TEST", {primary_activity: "social"})
    assert_nil @fleet.reload.primary_activity
  end
end
