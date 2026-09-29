# frozen_string_literal: true

# A verified RSI handle is held by one account at a time, and the latest proof
# wins: a Citizen iD sign-in and a token in the RSI bio both show control of the
# RSI account right now, so whichever came last takes the handle from whoever
# held it before.
module RsiHandleVerificationConcern
  extend ActiveSupport::Concern

  RSI_VERIFICATION_COOLDOWN = 1.minute

  included do
    enum :rsi_verification_status, {
      pending: "pending",
      verified: "verified",
      token_missing: "token_missing",
      handle_mismatch: "handle_mismatch",
      not_found: "not_found",
      failed: "failed"
    }, prefix: :rsi_verification

    enum :rsi_handle_verified_via, {
      citizenid: "citizenid",
      rsi_profile: "rsi_profile"
    }, prefix: :rsi_handle_verified_via

    before_create -> { self.rsi_verification_token ||= self.class.new_rsi_verification_token }

    # A new handle has proved nothing yet, and a check still out for the old
    # one no longer answers anything.
    before_save :reset_rsi_handle_verification,
      if: -> { rsi_handle_changed? && !rsi_handle_verified_at_changed? }
    before_save :release_rsi_handle_elsewhere, if: :claiming_rsi_handle?
    after_commit :notify_rsi_handle_lost, on: %i[create update]
  end

  class_methods do
    # Not a secret: it is meant to be pasted on a public page, and all it can
    # ever prove is that this account reached that page.
    def new_rsi_verification_token
      "FLEETYARDS-#{SecureRandom.alphanumeric(10).upcase}"
    end
  end

  def verify_rsi_handle(handle, via:)
    self.rsi_handle = handle
    self.rsi_handle_verified = true
    self.rsi_handle_verified_via = via
    self.rsi_handle_verified_at = Time.current
    self.rsi_verification_status = (via.to_s == "rsi_profile") ? :verified : nil
  end

  def clear_rsi_handle_verification
    self.rsi_handle_verified = false
    self.rsi_handle_verified_via = nil
    self.rsi_handle_verified_at = nil
  end

  # Written past validation: a user saved before a later check must still be
  # able to get a token or drop a verification.
  # rubocop:disable Rails/SkipsModelValidations
  def generate_rsi_verification_token!
    update_columns(
      rsi_verification_token: self.class.new_rsi_verification_token,
      rsi_verification_status: nil,
      updated_at: Time.current
    )
  end

  # The token is replaced too: left in place, the same token still in the bio
  # would verify the handle again on its next check.
  def revoke_rsi_handle_verification!
    update_columns(
      rsi_handle_verified: false,
      rsi_handle_verified_via: nil,
      rsi_handle_verified_at: nil,
      rsi_verification_status: nil,
      rsi_verification_token: self.class.new_rsi_verification_token,
      updated_at: Time.current
    )
  end
  # rubocop:enable Rails/SkipsModelValidations

  # updated_at keeps whole seconds, so a check answering within the second of
  # the request that started it would leave a cached payload unverified.
  def rsi_handle_verification_cache_key
    [rsi_handle_verified, rsi_handle_verified_via, rsi_handle_verified_at&.utc&.iso8601(6)]
  end

  def rsi_verification_cooling_down?
    rsi_verification_checked_at.present? &&
      rsi_verification_checked_at > RSI_VERIFICATION_COOLDOWN.ago
  end

  private def reset_rsi_handle_verification
    clear_rsi_handle_verification
    self.rsi_verification_status = nil
    self.rsi_verification_checked_at = nil
  end

  private def claiming_rsi_handle?
    rsi_handle_verified? && rsi_handle.present? &&
      (rsi_handle_verified_changed? || rsi_handle_changed?)
  end

  private def release_rsi_handle_elsewhere
    holders = self.class
      .where(rsi_handle_verified: true)
      .where("lower(rsi_handle) = lower(?)", rsi_handle)
      .where.not(id:)
      .lock
      .pluck(:id)

    return if holders.empty?

    # rubocop:disable Rails/SkipsModelValidations
    self.class.where(id: holders).update_all(
      rsi_handle_verified: false,
      rsi_handle_verified_via: nil,
      rsi_handle_verified_at: nil,
      rsi_verification_status: nil,
      updated_at: Time.current
    )
    # rubocop:enable Rails/SkipsModelValidations

    @rsi_handle_released = {handle: rsi_handle, user_ids: holders}
  end

  # The handle has already moved by now, so one holder who cannot be told must
  # not undo that or keep the others from hearing of it.
  private def notify_rsi_handle_lost
    released = @rsi_handle_released
    @rsi_handle_released = nil
    return if released.blank?

    self.class.where(id: released[:user_ids]).find_each do |user|
      I18n.with_locale(user.notification_locale) do
        Notification.notify!(
          user:,
          type: :rsi_handle_verification_lost,
          title: I18n.t("notifications.rsi_handle_verification_lost.title", handle: released[:handle]),
          body: I18n.t("notifications.rsi_handle_verification_lost.body", handle: released[:handle]),
          link: Rails.application.routes.url_helpers.frontend_profile_settings_path,
          icon: "fa-duotone fa-badge-check"
        )
      end
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
