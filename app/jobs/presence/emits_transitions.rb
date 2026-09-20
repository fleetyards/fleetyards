# frozen_string_literal: true

module Presence
  # Hands each transition a reconcile produced to the fan-out.
  #
  # The announced set moves before the jobs are enqueued, which is what keeps
  # two passes racing from emitting one transition each — so an enqueue that
  # fails has to be put back, or the next pass would see the deduplicated state
  # and say nothing.
  module EmitsTransitions
    # Nested rather than a sibling constant: zeitwerk maps this file to
    # `Presence::EmitsTransitions` and nothing else, so a `Presence::…` defined
    # beside it is never autoloaded.
    class EnqueueFailed < StandardError; end

    private def emit(transitions)
      failures = []

      transitions.each do |user_id, online|
        BroadcastTransitionJob.perform_async(
          user_id, BroadcastTransitionJob::REASON_CONNECTION
        )
      rescue => e
        # Every one of them, not just the first: `reconcile` committed the whole
        # batch before this loop started, so stopping here would leave the rest
        # committed and unsent, and no later pass would ever say them again.
        ::UserPresence.revert(user_id, online)
        failures << "#{user_id} (#{e.class})"
      end

      return if failures.empty?

      raise EnqueueFailed, "#{failures.size} transition(s) left for the next pass: #{failures.first(5).join(", ")}"
    end
  end
end
