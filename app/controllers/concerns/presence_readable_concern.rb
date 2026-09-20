# frozen_string_literal: true

# The presence set, read once per request.
#
# A rendered roster asks about every row, and the answer is one sorted set: one
# read for the whole page rather than one per member. What each side is allowed
# to do with the answer differs — a co-member's view is gated and redacted,
# an admin's is neither — so only the read itself is shared.
module PresenceReadableConcern
  extend ActiveSupport::Concern

  included do
    helper PresenceHelper
  end

  private def online_user_ids
    @online_user_ids ||= ::UserPresence.online_user_ids
  end
end
