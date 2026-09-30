# frozen_string_literal: true

module Cleanup
  class PushSubscriptionsJob < ::Cleanup::BaseJob
    def perform
      PushSubscription.stale.in_batches(of: 1000).delete_all
    end
  end
end
