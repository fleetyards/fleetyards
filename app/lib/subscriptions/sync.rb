# frozen_string_literal: true

module Subscriptions
  # The importers propose; this decides (D9).
  #
  # No importer writes a subscription itself. `Patreon::SupporterImporter` and
  # `Kofi::PaymentImporter` keep doing one job -- recording what was paid -- and
  # this reads the result. Two reasons, and both are load-bearing: a manual
  # grant has to survive a sync that knows nothing about it, and reconciliation
  # has to run when a *nomination* changes, which is not a payment event at all.
  #
  # Reconciles per fleet rather than per contribution. A fleet is entitled if
  # *any* contribution nominates it, is active, and clears the figure -- so the
  # question "should this fleet have one" has a single answer however many
  # contributions point at it, and asking it that way is what makes a second run
  # write nothing.
  class Sync
    LOCK = "subscriptions_sync"

    def self.call(date: Date.current)
      new(date:).call
    end

    def initialize(date: Date.current)
      @date = date
    end

    # Opened and closed subscriptions, so a caller -- a job, a test, an admin
    # task -- can report what a run actually did rather than that it finished.
    #
    # Serialized, and every read happens inside the lock. Without it two runs
    # interleave: one snapshots a nomination, a request clears it, and the first
    # run then opens a subscription nothing entitles -- reproduced before this
    # was added. The unique index cannot catch that, because a stale decision is
    # still a well-formed row.
    #
    # It waits rather than skipping. A run that gave up would leave exactly the
    # state it was enqueued to correct, and since every trigger enqueues one,
    # waiting is what makes the system converge.
    def call
      ActiveRecord::Base.with_advisory_lock(LOCK) do
        {opened: open_missing, closed: close_lapsed}
      end
    end

    private def open_missing
      opened = []

      entitled_fleet_ids.each do |fleet_id, contribution|
        next if open_subscriptions.key?(fleet_id)

        subscription = FleetSubscription.create!(
          fleet_id:,
          started_at: @date,
          granted_via: "contribution",
          supporter_contribution_id: contribution.id
        )
        Notifier.started(subscription)
        opened << subscription
      rescue ActiveRecord::RecordNotUnique
        # Another run, or another request, opened one between the read and the
        # write. The partial unique index is the authority and it just said this
        # fleet has one, which is the outcome this wanted anyway.
        next
      end

      opened
    end

    # Only subscriptions this opened. A grant with no contribution behind it is
    # somebody's decision -- a comp, a partner org, an answered support ticket,
    # a #4958 grace row -- and it closes by hand or by its own `ended_at`.
    private def close_lapsed
      closed = []

      open_subscriptions.each do |fleet_id, subscription|
        next unless subscription.granted_via_contribution?
        next if entitled_fleet_ids.key?(fleet_id)

        subscription.update!(ended_at: @date)

        Notifier.ended(subscription, cause: :contribution)
        closed << subscription
      end

      closed
    end

    # Fleet id => the contribution that entitles it, for every fleet with at
    # least one active, nominated, qualifying contribution.
    #
    # Memoised because both halves ask for it and the second must see exactly
    # what the first did: recomputing between them would let a contribution that
    # lapsed mid-run close a subscription the same run had just opened.
    private def entitled_fleet_ids
      @entitled_fleet_ids ||= candidate_contributions.each_with_object({}) do |contribution, fleets|
        next unless Subscriptions.qualifying?(contribution)

        fleets[contribution.fleet_id] ||= contribution
      end
    end

    private def candidate_contributions
      SupporterContribution
        .where.not(fleet_id: nil)
        .active_now(@date)
        .order(:started_at)
    end

    private def open_subscriptions
      @open_subscriptions ||= FleetSubscription.open.index_by(&:fleet_id)
    end
  end
end
