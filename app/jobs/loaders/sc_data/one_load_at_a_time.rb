# frozen_string_literal: true

module Loaders
  module ScData
    # One sc_data load at a time, across every worker. Models, hardpoints and
    # crew positions are shared between environments, so the live and ptu loads
    # `CheckJob` enqueues together walk the same models in the same order and
    # rewrite the same rows -- two `ModelPosition.generate_for_model!` calls
    # on one ship both pass the uniqueness validation and the second insert
    # dies on the index.
    #
    # A job that finds the lock taken goes back on the queue instead of
    # waiting: a full load holds it for twenty minutes, and a blocked thread
    # is one of the two each worker has.
    module OneLoadAtATime
      LOCK = "sc_data_load"
      RETRY_IN = 5.minutes

      private def one_load_at_a_time(*args, &)
        result = ActiveRecord::Base.with_advisory_lock_result(LOCK, timeout_seconds: 0, &)

        self.class.perform_in(RETRY_IN, *args) unless result.lock_was_acquired?
      end
    end
  end
end
