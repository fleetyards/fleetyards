# frozen_string_literal: true

# One stream for everybody, signed in or not: the raffle page is public, and
# the message only says which raffle changed, so each reader refetches it in
# their own language and with their own entry.
class RafflesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "raffles"
  end

  def unsubscribed
    stop_all_streams
  end
end
