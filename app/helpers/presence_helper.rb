# frozen_string_literal: true

module PresenceHelper
  # Whether a user reads as online *to whoever this render is for*, or `nil`
  # when that question has no answer here.
  #
  # It has none in a payload rendered from a model — every cable broadcast goes
  # through `to_jbuilder_hash`, which renders one payload and sends it to many
  # recipients, so there is no reader to gate or redact against. Absent is the
  # right answer there: the client patches presence from its own subscription.
  def online_status_for(user)
    return unless controller.respond_to?(:online_status_for)

    controller.online_status_for(user)
  end
end
