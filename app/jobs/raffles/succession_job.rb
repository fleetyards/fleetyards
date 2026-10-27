# frozen_string_literal: true

module Raffles
  # Moves every win whose claim deadline has passed on to the next entrant.
  class SuccessionJob < ::ApplicationJob
    sidekiq_options retry: true, queue: "default"

    def perform
      raffle_ids = RaffleEntry.claim_expired.distinct.pluck(:raffle_id)

      Raffle.where(id: raffle_ids).find_each do |raffle|
        Succession.new(raffle).call
      end
    end
  end
end
