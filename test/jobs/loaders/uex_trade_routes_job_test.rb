# frozen_string_literal: true

require "test_helper"

module Loaders
  class UexTradeRoutesJobTest < ActiveJob::TestCase
    setup do
      create(:admin_user, :super_admin)
    end

    test "#perform syncs terminals before routes" do
      sequence = sequence("terminals before routes")
      stub_syncer(::Uex::TerminalSyncer, terminal_result).in_sequence(sequence)
      stub_syncer(::Uex::TradeRouteSyncer, route_result).in_sequence(sequence)

      ::Loaders::UexTradeRoutesJob.new.perform
    end

    test "#perform stays quiet on a clean run" do
      stub_syncer(::Uex::TerminalSyncer, terminal_result)
      stub_syncer(::Uex::TradeRouteSyncer, route_result)

      assert_no_difference -> { AdminNotification.count } do
        ::Loaders::UexTradeRoutesJob.new.perform
      end
    end

    test "#perform reports the commodities it could not fetch, without an issue" do
      gold = build(:commodity, name: "Gold", uex_id: 33)
      stub_syncer(::Uex::TerminalSyncer, terminal_result)
      stub_syncer(::Uex::TradeRouteSyncer, route_result(failed: [gold]))
      GithubIssueCreator.expects(:new).never

      ::Loaders::UexTradeRoutesJob.new.perform

      notification = AdminNotification.where(notification_type: "uex_trade_routes_sync").sole
      assert_predicate notification, :severity_warning?
      assert_includes notification.body, "**Gold** — UEX id `33`"
    end

    test "#perform updates one notification while the same failure repeats" do
      gold = build(:commodity, name: "Gold", uex_id: 33)
      stub_syncer(::Uex::TerminalSyncer, terminal_result)
      stub_syncer(::Uex::TradeRouteSyncer, route_result(failed: [gold]))

      2.times { ::Loaders::UexTradeRoutesJob.new.perform }

      assert_equal 2, AdminNotification.where(notification_type: "uex_trade_routes_sync").sole.occurrences
    end

    private def stub_syncer(klass, result)
      syncer = mock(klass.name)
      klass.stubs(:new).returns(syncer)
      syncer.expects(:run).at_least_once.returns(result)
    end

    private def terminal_result
      ::Uex::TerminalSyncer::Result.new(created: 0, updated: 2, retired: 0, terminals: {})
    end

    private def route_result(failed: [])
      ::Uex::TradeRouteSyncer::Result.new(commodities: 2, routes: 3, failed:, unprofitable: 2, unknown_terminals: 1)
    end
  end
end
