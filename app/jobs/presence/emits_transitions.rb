# frozen_string_literal: true

module Presence
  # Hands each transition a reconcile produced to the fan-out.
  #
  # The announced set moves before the job is enqueued, which is what keeps two
  # passes racing from emitting one transition each — so a failed enqueue has to
  # be put back, or the next pass would see the deduplicated state and say
  # nothing.
  module EmitsTransitions
    private def emit(transitions)
      transitions.each do |user_id, online|
        BroadcastTransitionJob.perform_async(
          user_id, online, BroadcastTransitionJob::REASON_CONNECTION
        )
      rescue
        ::UserPresence.revert(user_id, online)
        raise
      end
    end
  end
end
