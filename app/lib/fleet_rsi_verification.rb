# frozen_string_literal: true

# Checks that a fleet's verification token is on its RSI org's public page.
#
# Only the org's officers can edit that page, so finding the token there is
# taken as proof that whoever asked runs the org -- which is why the latest
# proof wins: a fleet that held the SID before loses it to the one that just
# showed it controls the page.
class FleetRsiVerification
  attr_reader :fleet

  def initialize(fleet)
    @fleet = fleet
  end

  def run
    sid = fleet.rsi_sid
    token = fleet.rsi_verification_token

    return record(:failed) if sid.blank? || token.blank?

    status = status_for(Rsi::OrgPage.fetch(sid), sid:, token:)

    # The SID or the token may have changed while the page was loading; the
    # answer is then about something the fleet no longer asks.
    fleet.reload
    return if fleet.rsi_sid != sid || fleet.rsi_verification_token != token

    (status == :verified) ? verify!(sid) : record(status)
  end

  private def status_for(page, sid:, token:)
    return page.status unless page.status == :ok
    return :symbol_mismatch unless page.symbol == sid
    return :token_missing unless page.text.include?(token)

    :verified
  end

  private def record(status)
    fleet.update_columns(rsi_verification_status: status, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    status
  end

  private def verify!(sid)
    now = Time.current

    previous = Fleet.transaction do
      previous = Fleet.kept.where(rsi_verified_sid: sid).where.not(id: fleet.id).lock.to_a

      # rubocop:disable Rails/SkipsModelValidations
      previous.each do |other|
        other.update_columns(rsi_verified_at: nil, rsi_verified_sid: nil, rsi_verification_status: nil, updated_at: now)
      end

      fleet.update_columns(rsi_verified_at: now, rsi_verified_sid: sid, rsi_verification_status: :verified, updated_at: now)
      # rubocop:enable Rails/SkipsModelValidations

      previous
    end

    previous.each { |other| notify_lost(other, sid) }

    :verified
  end

  private def notify_lost(other, sid)
    other.rsi_verification_managers.each do |user|
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
  end
end
