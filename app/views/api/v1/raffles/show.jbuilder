# frozen_string_literal: true

json.partial! "api/v1/raffles/raffle", raffle: @raffle, viewer_entry: @viewer_entries[@raffle.id]
