# frozen_string_literal: true

module Presence
  # The backstop for every connection that ended without a callback: a killed
  # worker, a container replaced mid-deploy, a phone leaving a tunnel. Those
  # connections age out of the set on their own, but an expiring score fires no
  # event, so somebody has to notice.
  #
  # Runs every minute. It reads one sorted set and one set, so the cost does not
  # depend on how many users exist — only on how many are connected.
  class SweepJob < ::ApplicationJob
    sidekiq_options queue: "default", retry: false

    def perform
      ::UserPresence.reconcile.each do |user_id, online|
        BroadcastTransitionJob.perform_async(user_id, online)
      end
    end
  end
end
