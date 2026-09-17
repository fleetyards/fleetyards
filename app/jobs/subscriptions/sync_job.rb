# frozen_string_literal: true

module Subscriptions
  # Reconciliation off the request path.
  #
  # The Ko-fi webhook and the nomination endpoint both enqueue this rather than
  # reconciling inline: neither should get slower, or fail, because of work that
  # is allowed to happen a moment later. The Patreon job already runs in the
  # background and calls the reconciler directly.
  class SyncJob < ::ApplicationJob
    sidekiq_options queue: "default", retry: 3

    def perform
      stats = Subscriptions::Sync.call

      Rails.logger.info(
        "[SubscriptionsSync] opened=#{stats[:opened].size} closed=#{stats[:closed].size}"
      )

      stats
    end
  end
end
