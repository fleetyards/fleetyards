# frozen_string_literal: true

module Raffles
  # Hands the win to the next entrant in draw order once the current winner's
  # claim deadline has passed, or to the first one right after the draw.
  #
  # An entrant whose account is gone or no longer confirmed by the time their
  # turn comes is passed over: they can only be told through the account.
  class Succession
    def initialize(raffle, now: Time.current)
      @raffle = raffle
      @now = now
    end

    # Returns the new winner, or nil when the current one still has time, the
    # code is claimed or nobody is left.
    def call
      winner = @raffle.with_lock { advance }
      notify(winner) if winner
      winner
    end

    private def advance
      return if @raffle.concluded? || !@raffle.drawn?

      current = @raffle.current_winner
      if current
        return if current.claimed_at.present? || current.claim_deadline_at > @now

        current.update!(forfeited_at: @now)
      end

      next_winner = promote_next
      @raffle.conclude!(@now) if next_winner.nil?
      next_winner
    end

    private def promote_next
      candidates = @raffle.entries.includes(:user)
        .where(won_at: nil, forfeited_at: nil)
        .where.not(draw_position: nil)
        .order(:draw_position)

      candidates.each do |entry|
        unless entry.user&.confirmed?
          entry.update!(forfeited_at: @now)
          next
        end

        entry.update!(won_at: @now, claim_deadline_at: @now + @raffle.claim_period_days.days)
        return entry
      end

      nil
    end

    private def notify(entry)
      user = entry.user
      I18n.with_locale(user.notification_locale) do
        Notification.notify!(
          user:,
          type: :raffle_won,
          title: I18n.t("notifications.raffle_won.title", raffle: @raffle.title),
          body: I18n.t(
            "notifications.raffle_won.body",
            raffle: @raffle.title,
            deadline: I18n.l(entry.claim_deadline_at, format: :long)
          ),
          link: Rails.application.routes.url_helpers.frontend_raffle_path(@raffle),
          icon: "fa-duotone fa-gift",
          record: entry
        )
      end
    rescue => error
      # The win stands and the deadline runs either way; a notification that
      # failed must not undo the promotion the lock already committed.
      Rails.logger.error("Could not notify raffle winner #{entry.id}: #{error.message}")
      Appsignal.report_error(error)
    end
  end
end
