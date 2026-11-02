# frozen_string_literal: true

module Raffles
  # Puts every eligible entrant of a closed raffle into one random order and
  # makes the first the winner. The whole order is fixed here, so whoever moves
  # up after a forfeited win was already decided at the draw -- nobody can
  # re-roll a later pick.
  class Draw
    Result = Struct.new(:status, :winner)

    def initialize(raffle, admin_user:, now: Time.current)
      @raffle = raffle
      @admin_user = admin_user
      @now = now
    end

    def call
      status = @raffle.with_lock { draw }
      return Result.new(status:) unless status == :drawn

      Result.new(status:, winner: Succession.new(@raffle, now: @now).call)
    end

    private def draw
      return :already_drawn if @raffle.drawn?
      return :not_closed unless @raffle.drawable?(@now)

      entries = eligible_entries
      return :no_entrants if entries.empty?

      entries.shuffle(random: SecureRandom).each.with_index(1) do |entry, position|
        entry.update_columns(draw_position: position, updated_at: @now)
      end
      @raffle.update!(drawn_at: @now, drawn_by: @admin_user)

      :drawn
    end

    private def eligible_entries
      @raffle.entries.includes(:user).select { |entry| entry.user&.raffle_eligible? }
    end
  end
end
