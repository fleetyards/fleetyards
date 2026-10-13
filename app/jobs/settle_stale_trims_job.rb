# frozen_string_literal: true

# A crop whose job vanished -- a worker killed mid-run loses it without a retry
# or a death -- never settles itself, and the edit page would wait on it for
# good. This takes such entries off once they are past PENDING_TRIM_TTL, which
# broadcasts like any other settled crop.
class SettleStaleTrimsJob
  include Sidekiq::Worker

  sidekiq_options queue: "preprocessing", retry: false

  def perform
    Model.where.not(pending_trims: {}).find_each(&:settle_stale_trims)
  end
end
