# frozen_string_literal: true

require "test_helper"

module Patreon
  class SupporterImporterTest < ActiveSupport::TestCase
    class FakeClient
      def initialize(members)
        @members = members
      end

      def members(_campaign_id)
        @members
      end
    end

    def member(overrides = {})
      Patreon::Member.new(id: "m1",
        name: "Alice",
        status: "active_patron",
        amount_cents: 500,
        pledged_at: Date.new(2026, 1, 15),
        last_charge_date: Date.new(2026, 6, 1), **overrides)
    end

    def import(members)
      Patreon::SupporterImporter.call(client: FakeClient.new(members), campaign_id: "camp-1")
    end

    test "creates an anonymous, recurring, EUR-converted row for a new active patron" do
      ExchangeRateFetcher.stubs(:convert_cents).with(500, from: "USD", to: "EUR").returns(460)

      stats = import([member])

      record = SupporterContribution.find_by(patreon_member_id: "m1")
      assert record.patreon?
      assert record.anonymous?
      assert record.recurring?
      assert_equal "Alice", record.name
      assert_equal 460, record.amount_cents
      assert_equal "EUR", record.currency
      assert_equal 500, record.source_amount_cents
      assert_equal "USD", record.source_currency
      assert_equal Date.new(2026, 1, 15), record.started_at
      assert_nil record.ended_at
      assert_equal({created: 1, updated: 0, ended: 0, skipped: 0}, stats)
    end

    test "enqueues a new-patron notification for a newly-created active patron" do
      ExchangeRateFetcher.stubs(:convert_cents).returns(460)
      Sidekiq::Worker.clear_all

      import([member])

      assert_equal 1, Notifications::NewPatronJob.jobs.size
      assert_equal SupporterContribution.find_by(patreon_member_id: "m1").id,
        Notifications::NewPatronJob.jobs.first["args"].first
    end

    test "does not enqueue a notification when an existing patron is updated" do
      ExchangeRateFetcher.stubs(:convert_cents).returns(460)
      import([member])
      Sidekiq::Worker.clear_all

      import([member(amount_cents: 1000)])

      assert_equal 0, Notifications::NewPatronJob.jobs.size
    end

    test "does not enqueue a notification for a member created already churned" do
      ExchangeRateFetcher.stubs(:convert_cents).returns(460)
      Sidekiq::Worker.clear_all

      import([member(status: "former_patron", last_charge_date: Date.new(2026, 5, 20))])

      assert_equal 0, Notifications::NewPatronJob.jobs.size
    end

    test "skips free-tier members with no positive amount" do
      stats = import([member(amount_cents: 0)])

      assert_nil SupporterContribution.find_by(patreon_member_id: "m1")
      assert_equal({created: 0, updated: 0, ended: 0, skipped: 1}, stats)
    end

    test "ends an existing record for a former patron even when amount drops to zero" do
      ExchangeRateFetcher.stubs(:convert_cents).returns(460)

      import([member])
      stats = import([member(status: "former_patron", amount_cents: 0, last_charge_date: Date.new(2026, 5, 20))])

      record = SupporterContribution.find_by(patreon_member_id: "m1")
      assert_equal Date.new(2026, 5, 20), record.ended_at
      assert_equal({created: 0, updated: 1, ended: 1, skipped: 0}, stats)
    end

    test "does not re-convert when the source amount is unchanged" do
      ExchangeRateFetcher.expects(:convert_cents).with(500, from: "USD", to: "EUR").once.returns(460)

      import([member])
      stats = import([member])

      record = SupporterContribution.find_by(patreon_member_id: "m1")
      assert_equal 460, record.amount_cents
      assert_equal({created: 0, updated: 0, ended: 0, skipped: 0}, stats)
    end

    test "re-converts when the source amount changes" do
      ExchangeRateFetcher.stubs(:convert_cents).with(500, from: "USD", to: "EUR").returns(460)
      ExchangeRateFetcher.stubs(:convert_cents).with(1000, from: "USD", to: "EUR").returns(920)

      import([member])
      stats = import([member(amount_cents: 1000)])

      record = SupporterContribution.find_by(patreon_member_id: "m1")
      assert_equal 920, record.amount_cents
      assert_equal 1000, record.source_amount_cents
      assert_equal({created: 0, updated: 1, ended: 0, skipped: 0}, stats)
    end

    test "ends a pledge when the patron becomes a former patron" do
      ExchangeRateFetcher.stubs(:convert_cents).returns(460)

      import([member])
      stats = import([member(status: "former_patron", last_charge_date: Date.new(2026, 5, 20))])

      record = SupporterContribution.find_by(patreon_member_id: "m1")
      assert_equal Date.new(2026, 5, 20), record.ended_at
      assert_equal({created: 0, updated: 1, ended: 1, skipped: 0}, stats)
    end

    test "keeps a declined patron active so Patreon can retry the charge" do
      ExchangeRateFetcher.stubs(:convert_cents).returns(460)

      import([member])
      stats = import([member(status: "declined_patron")])

      record = SupporterContribution.find_by(patreon_member_id: "m1")
      assert_nil record.ended_at
      assert_equal({created: 0, updated: 0, ended: 0, skipped: 0}, stats)
    end

    test "raises when no campaign_id is configured" do
      assert_raises(Patreon::Error) do
        Patreon::SupporterImporter.call(client: FakeClient.new([]), campaign_id: nil)
      end
    end
  end
end
