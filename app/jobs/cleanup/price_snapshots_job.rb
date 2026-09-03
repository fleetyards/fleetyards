# frozen_string_literal: true

module Cleanup
  class PriceSnapshotsJob < ::Cleanup::BaseJob
    # Two years of daily prices per terminal. Production holds roughly 3,500
    # priced locations across commodities and ships, so this settles at a few
    # million rows rather than growing without end.
    RETENTION = 24.months

    def perform
      cutoff = RETENTION.ago.to_date

      ItemPriceSnapshot.where(recorded_on: ...cutoff).in_batches(of: 10_000).delete_all
    end
  end
end
