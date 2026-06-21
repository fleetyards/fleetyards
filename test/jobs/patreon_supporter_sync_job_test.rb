# frozen_string_literal: true

require "test_helper"

class PatreonSupporterSyncJobTest < ActiveJob::TestCase
  test "#perform runs the importer and returns its stats" do
    stats = {created: 2, updated: 1, ended: 0, skipped: 3}
    Patreon::SupporterImporter.expects(:call).returns(stats)

    assert_equal stats, PatreonSupporterSyncJob.new.perform
  end

  test "#perform swallows Patreon::Error and reports it to AppSignal" do
    Patreon::SupporterImporter.stubs(:call).raises(Patreon::Error, "token expired")
    Appsignal.expects(:report_error).once

    assert_nothing_raised do
      PatreonSupporterSyncJob.new.perform
    end
  end

  test "#perform re-raises unexpected errors so Sidekiq can retry" do
    Patreon::SupporterImporter.stubs(:call).raises(StandardError, "boom")

    assert_raises(StandardError) do
      PatreonSupporterSyncJob.new.perform
    end
  end
end
