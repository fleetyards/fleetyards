# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class FleetRsiRefreshJobTest < ActiveSupport::TestCase
  setup do
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @previous_cache
  end

  def verified_fleet(sid, attempted_at: nil)
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: sid)
    fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: sid, rsi_sync_attempted_at: attempted_at) # rubocop:disable Rails/SkipsModelValidations
    fleet
  end

  def stub_rsi(status: 500)
    stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/en/orgs/}).to_return(status:)
    stub_request(:post, "https://robertsspaceindustries.com/api/orgs/getOrgs").to_return(status:)
  end

  def asked
    Fleet.where(rsi_sync_attempted_at: 1.minute.ago..).pluck(:rsi_sid).sort
  end

  test "each run takes a 24th of the verified fleets, the longest unasked first" do
    25.times { |index| verified_fleet("ORG#{index}", attempted_at: (index + 21).hours.ago) }
    create(:fleet, rsi_sid: "UNVERIFIED")
    stub_rsi

    FleetRsiRefreshJob.new.perform

    assert_equal %w[ORG23 ORG24], asked
  end

  test "a fleet asked within the day is left alone" do
    verified_fleet("RECENT", attempted_at: 1.hour.ago)
    stub_rsi

    FleetRsiRefreshJob.new.perform

    assert_not_requested :get, %r{/orgs/}
  end

  test "a block pauses the refresh for the rest of the day" do
    verified_fleet("ONE")
    verified_fleet("TWO")
    stub_rsi(status: 403)

    FleetRsiRefreshJob.new.perform

    assert Rails.cache.read(FleetRsiRefreshJob::PAUSE_KEY)
    assert_equal 1, asked.size

    FleetRsiRefreshJob.new.perform

    assert_equal 1, asked.size
  end
end
