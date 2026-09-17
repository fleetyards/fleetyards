# frozen_string_literal: true

require "test_helper"

class PatreonSupporterSyncJobTest < ActiveJob::TestCase
  test "#perform runs the importer and returns its stats" do
    PatreonSupporterSyncJob.stubs(:configured?).returns(true)
    stats = {created: 2, updated: 1, ended: 0, skipped: 3}
    Patreon::SupporterImporter.expects(:call).returns(stats)

    assert_equal stats, PatreonSupporterSyncJob.new.perform
  end

  test "#perform is a no-op when patreon credentials are not configured" do
    PatreonSupporterSyncJob.stubs(:configured?).returns(false)
    Patreon::SupporterImporter.expects(:call).never

    assert_nil PatreonSupporterSyncJob.new.perform
  end

  test "#perform swallows Patreon::Error and reports it to AppSignal" do
    PatreonSupporterSyncJob.stubs(:configured?).returns(true)
    Patreon::SupporterImporter.stubs(:call).raises(Patreon::Error, "token expired")
    Appsignal.expects(:report_error).once

    assert_nothing_raised do
      PatreonSupporterSyncJob.new.perform
    end
  end

  test "#perform re-raises unexpected errors so Sidekiq can retry" do
    PatreonSupporterSyncJob.stubs(:configured?).returns(true)
    Patreon::SupporterImporter.stubs(:call).raises(StandardError, "boom")

    assert_raises(StandardError) do
      PatreonSupporterSyncJob.new.perform
    end
  end

  # The importer records what was paid; entitlement is decided from the result.
  test "#perform reconciles subscriptions after importing" do
    PatreonSupporterSyncJob.stubs(:configured?).returns(true)
    Patreon::SupporterImporter.stubs(:call).returns({created: 1})
    Subscriptions::Sync.expects(:call).once

    PatreonSupporterSyncJob.new.perform
  end

  # A failed import has nothing new to reconcile, and the error is already
  # reported -- running anyway would only add a second way for the job to fail.
  test "#perform does not reconcile when the import failed" do
    PatreonSupporterSyncJob.stubs(:configured?).returns(true)
    Patreon::SupporterImporter.stubs(:call).raises(Patreon::Error, "token expired")
    Appsignal.stubs(:report_error)
    Subscriptions::Sync.expects(:call).never

    PatreonSupporterSyncJob.new.perform
  end
end
