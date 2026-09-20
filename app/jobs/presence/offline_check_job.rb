# frozen_string_literal: true

module Presence
  # Settles one user once the grace tail their closing connection was given has
  # run out. Scheduled by `ApplicationCable::Connection#disconnect`, which is
  # the only path that knows a connection ended on purpose.
  #
  # A reload comes through here too and emits nothing: the replacement
  # connection is live by the time this runs, so the reconcile finds no change.
  class OfflineCheckJob < ::ApplicationJob
    include EmitsTransitions

    sidekiq_options queue: "default", retry: 3

    def perform(user_id)
      emit(::UserPresence.reconcile(user_ids: [user_id]))
    end
  end
end
