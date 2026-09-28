# frozen_string_literal: true

# Checks that a fleet's verification token is on its RSI org's public page.
#
# Only the org's officers can edit that page, so finding the token there is
# taken as proof that whoever asked runs the org -- which is why the latest
# proof wins: a fleet that held the SID before loses it to the one that just
# showed it controls the page.
#
# A check is identified by the time it was asked for. Its answer is only
# written while that is still the fleet's latest check and the SID and token
# are the ones it looked for: a slow check must not overwrite a newer one, and
# one that outlived a revoke or a new SID answers a question nobody asks.
class FleetRsiVerification
  attr_reader :fleet

  def self.generation_of(checked_at)
    checked_at&.utc&.iso8601(6)
  end

  # For a check that raised: failed rather than left pending, which would keep
  # the settings page waiting -- but only if nothing newer has answered since.
  def self.fail_if_current!(fleet, generation)
    fleet.with_lock do
      next unless fleet.rsi_verification_pending?
      next unless generation_of(fleet.rsi_verification_checked_at) == generation

      fleet.update_columns(rsi_verification_status: :failed, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def initialize(fleet, generation: nil)
    @fleet = fleet
    @generation = generation || self.class.generation_of(fleet.rsi_verification_checked_at)
  end

  def run
    sid = fleet.rsi_sid
    token = fleet.rsi_verification_token

    status = if sid.blank? || token.blank?
      :failed
    else
      status_for(Rsi::OrgPage.fetch(sid), sid:, token:)
    end

    apply(status, sid:, token:)
  end

  private def status_for(page, sid:, token:)
    return page.status unless page.status == :ok
    return :symbol_mismatch unless page.symbol == sid
    return :token_missing unless page.text.include?(token)

    :verified
  end

  # Locking the fleet serialises the answer against a revoke, a new token or
  # another check. Locking the holders serialises a takeover, but when nobody
  # holds the SID there is no row to lock, and two fleets proving it at once
  # both write it: the loser meets the unique index and goes again, with a
  # holder to take the SID from this time.
  private def apply(status, sid:, token:, attempts: 2)
    previous = []

    applied = Fleet.transaction do
      fleet.lock!

      next :stale unless self.class.generation_of(fleet.rsi_verification_checked_at) == @generation

      if fleet.rsi_sid != sid || fleet.rsi_verification_token != token
        write(rsi_verification_status: nil) if fleet.rsi_verification_pending?
        next :stale
      end

      if status == :verified
        previous = take_over!(sid)
      else
        write(rsi_verification_status: status)
      end

      status
    end

    return if applied == :stale

    previous.each { |other| notify_lost(other, sid) }

    applied
  rescue ActiveRecord::RecordNotUnique
    raise if (attempts -= 1).zero?

    retry
  end

  private def take_over!(sid)
    now = Time.current
    previous = Fleet.kept.where(rsi_verified_sid: sid).where.not(id: fleet.id).lock.to_a

    # rubocop:disable Rails/SkipsModelValidations
    previous.each do |other|
      other.update_columns(rsi_verified_at: nil, rsi_verified_sid: nil, rsi_verification_status: nil, updated_at: now)
    end
    # rubocop:enable Rails/SkipsModelValidations

    write(rsi_verified_at: now, rsi_verified_sid: sid, rsi_verification_status: :verified)

    previous
  end

  private def write(**columns)
    fleet.update_columns(**columns, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  # The SID has already moved by now, so one manager who cannot be told must
  # not undo that or keep the others from hearing of it. The text is stored,
  # so it is written in each manager's own language.
  private def notify_lost(other, sid)
    other.managers.each do |user|
      I18n.with_locale(user.notification_locale) do
        Notification.notify!(
          user:,
          type: :fleet_rsi_verification_lost,
          title: I18n.t("notifications.fleet_rsi_verification_lost.title", fleet: other.name, sid:),
          body: I18n.t("notifications.fleet_rsi_verification_lost.body", sid:),
          link: Rails.application.routes.url_helpers.frontend_fleet_settings_fleet_path(other.slug),
          icon: "fa-duotone fa-badge-check",
          record: other
        )
      end
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
