# frozen_string_literal: true

module Imports
  # How far a running import is: the step it is on, and how much of that step is
  # done. Kept on the row for whoever opens the page later, and broadcast to
  # whoever has it open now.
  #
  # Steps take very different times, so nothing adds them up to one percentage.
  class Progress
    STEPS = %w[
      fetch_tree
      manufacturers items models model_modules commodities
      equipment blueprints locations game_missions factions
    ].freeze

    # A load counts tens of thousands of records. Each write is an update and a
    # broadcast per admin, which is worth it only as often as a person looks.
    WRITE_EVERY = 3.seconds

    def initialize(import, steps:)
      @import = import
      @steps = steps
      @step_number = 0
      @lock = Mutex.new
    end

    def step(name, total: nil)
      @lock.synchronize do
        @step = name
        @step_number += 1
        @total = total
        @done = 0
        write
      end
    end

    # For a step whose size is only known once it has started.
    def total=(total)
      @lock.synchronize do
        @total = total
        @done = 0
        write
      end
    end

    # Called from the threads of a parallel transfer as well.
    def advance
      @lock.synchronize do
        @done += 1
        write if due?
      end
    end

    private def due?
      monotonic - @written_at >= WRITE_EVERY || @done == @total
    end

    # A progress report that cannot be written must not take the import with it.
    private def write
      @written_at = monotonic

      ActiveRecord::Base.connection_pool.with_connection do
        # Locked through the broadcast: an admin clearing the run in between
        # would have this copy, which still says `started`, bring it back on
        # their page.
        Import.transaction do
          next unless Import.started.lock.exists?(id: @import.id)

          now = Time.current

          # The read cache is keyed on `updated_at`.
          @import.update_columns(progress: payload, progressed_at: now, updated_at: now)
          @import.broadcast_to_admins
        end
      end
    rescue => e
      Rails.logger.warn("[imports] progress of #{@import.id} not recorded: #{e.class}: #{e.message}")
    end

    private def payload
      {step: @step, step_number: @step_number, steps: @steps, done: @done, total: @total}
    end

    private def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
