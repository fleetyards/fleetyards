# frozen_string_literal: true

# A fleet verified for an RSI SID asking for the fleet ID that equals it.
#
# The FID is also the fleet's slug, and there is no slug history, so moving it
# repoints every link to the holder -- the fleet URL, short event links, mail
# links. The holder gets a grace period to prove the SID itself, which cancels
# the claim because the latest proof wins, or to tell its members.
class FleetFidClaim < ApplicationRecord
  GRACE_PERIOD = 14.days

  belongs_to :claimant, class_name: "Fleet"
  belongs_to :holder, class_name: "Fleet", optional: true

  enum :state, {
    open: "open",
    completed: "completed",
    cancelled: "cancelled"
  }

  enum :cancel_reason, {
    withdrawn: "withdrawn",
    holder_verified: "holder_verified",
    claimant_unverified: "claimant_unverified",
    admin: "admin"
  }, prefix: :cancelled_by

  scope :due, -> { open.where(ends_at: ..Time.current) }

  AVAILABILITIES = %w[pending unverified invalid held available claimable].freeze

  # Why a fleet can or cannot claim, in the order the settings page asks.
  # `pending` is its own open claim; `held` means it already has the FID, and
  # `available` that nobody does, so the fleet can simply set it.
  def self.availability_for(fleet)
    return :pending if open.exists?(claimant: fleet)
    return :unverified unless fleet.rsi_verified?

    fid = fleet.rsi_verified_sid
    return :invalid unless Fleet.valid_fid?(fid)
    return :held if fleet.normalized_fid == fid.downcase

    holder_of(fid, except: fleet).present? ? :claimable : :available
  end

  def self.holder_of(fid, except: nil)
    scope = Fleet.kept.where(normalized_fid: fid.downcase)
    scope = scope.where.not(id: except.id) if except.present?
    scope.first
  end

  def self.reserved?(fid, except: nil)
    scope = open.where(fid: fid.to_s.upcase)
    scope = scope.where.not(claimant_id: except.id) if except.present?
    scope.exists?
  end

  # Nil when the fleet cannot claim. The claimed FID is always the verified
  # SID, so there is nothing for the caller to choose.
  def self.open_for!(claimant, user:)
    claim = transaction do
      claimant.lock!

      next unless availability_for(claimant) == :claimable

      fid = claimant.rsi_verified_sid

      create!(
        claimant:,
        holder: holder_of(fid, except: claimant),
        fid:,
        created_by: user&.id,
        ends_at: GRACE_PERIOD.from_now
      )
    end

    claim&.notify_opened

    claim
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  # A claim only stands while the claimant can still show it runs the org.
  # `verified_by` is the fleet that just proved the SID, which is the holder
  # when the holder chose to keep its FID that way.
  def self.cancel_for_lost_verification!(claimant, verified_by: nil)
    open.where(claimant:).find_each do |claim|
      reason = (verified_by.present? && claim.holder_id == verified_by.id) ? :holder_verified : :claimant_unverified

      claim.cancel!(reason)
    end
  end

  def self.complete_due!
    due.find_each do |claim|
      claim.complete!
    rescue => e
      Appsignal.report_error(e)
    end
  end

  def cancel!(reason)
    cancelled = with_lock do
      next false unless open?

      update!(state: :cancelled, cancel_reason: reason, cancelled_at: Time.current)
    end

    notify_cancelled if cancelled

    cancelled
  end

  # Locks the claim, then the claimant, then the fleet holding the FID now --
  # which may not be the holder the claim was opened against, if that fleet
  # renamed itself in the meantime.
  def complete!
    outcome = transaction do
      lock!

      next unless open? && ends_at <= Time.current

      fleet = Fleet.lock.find(claimant_id)

      unless fleet.kept? && fleet.rsi_verified? && fleet.rsi_verified_sid == fid
        update!(state: :cancelled, cancel_reason: :claimant_unverified, cancelled_at: Time.current)
        next :cancelled
      end

      current_holder = Fleet.kept.lock.where(normalized_fid: fid.downcase).where.not(id: fleet.id).first

      # A fleet that took the FID after the claim was opened -- in the moment
      # between the check and the reservation, or by a restore that skips
      # validation -- was never warned. It gets the notice and a grace period
      # of its own rather than a rename out of the blue.
      if current_holder.present? && current_holder.id != holder_id
        update!(holder: current_holder, ends_at: GRACE_PERIOD.from_now)
        next :restarted
      end

      if current_holder.present?
        self.holder = current_holder
        self.holder_previous_fid = current_holder.fid
        self.holder_new_fid = Fleet.next_free_fid(fid)

        rename!(current_holder, holder_new_fid)
      end

      rename!(fleet, fid) unless fleet.normalized_fid == fid.downcase

      update!(state: :completed, completed_at: Time.current)

      :completed
    end

    case outcome
    when :completed then notify_completed
    when :cancelled then notify_cancelled
    when :restarted then notify_opened
    end

    outcome
  end

  def notify_opened
    notify_managers(holder, :fleet_fid_claim_opened, claimant: claimant.name)
  end

  private def notify_completed
    notify_managers(claimant, :fleet_fid_claim_completed, variant: :claimant)

    return if holder_new_fid.blank?

    notify_managers(holder, :fleet_fid_claim_completed, variant: :holder,
      claimant: claimant.name, new_fid: holder_new_fid)
  end

  private def notify_cancelled
    notify_managers(holder, :fleet_fid_claim_cancelled, variant: :"holder_#{cancel_reason}",
      claimant: claimant.name)

    return if cancelled_by_withdrawn?

    notify_managers(claimant, :fleet_fid_claim_cancelled, variant: :"claimant_#{cancel_reason}",
      holder: holder&.name || fid)
  end

  # Written past validation: this is the system moving an FID, and neither
  # fleet must be kept from losing or taking one by an unrelated field that a
  # later check would reject. `normalized_fid` is set by hand because it is
  # derived in a validation callback.
  private def rename!(fleet, new_fid)
    fleet.fid = new_fid
    fleet.normalized_fid = new_fid.downcase
    fleet.save!(validate: false)
  end

  # The text is stored, so it is written in each manager's own language, and
  # one manager who cannot be told must not keep the others from hearing of it.
  private def notify_managers(fleet, type, variant: nil, **vars)
    return if fleet.blank? || fleet.discarded?

    key = ["notifications", type, variant].compact.join(".")
    link = Rails.application.routes.url_helpers.frontend_fleet_settings_rsi_path(fleet.slug)

    fleet.managers.each do |user|
      I18n.with_locale(user.notification_locale) do
        Notification.notify!(
          user:,
          type:,
          title: I18n.t("#{key}.title", fleet: fleet.name, fid:, **vars),
          body: I18n.t("#{key}.body", fleet: fleet.name, fid:, date: I18n.l(ends_at.to_date, format: :long), **vars),
          link:,
          icon: "fa-duotone fa-id-badge",
          record: self
        )
      end
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
