# frozen_string_literal: true

json.array! @payout_participants, partial: "api/v1/payout_participants/payout_participant", as: :payout_participant
