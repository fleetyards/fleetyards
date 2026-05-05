# frozen_string_literal: true

class FleetEventSignup < ApplicationRecord
  STATUSES = %w[confirmed tentative withdrawn].freeze

  belongs_to :fleet_event_slot, touch: true
  belongs_to :fleet_membership
  belongs_to :vehicle, optional: true

  validates :status, inclusion: {in: STATUSES}
  validate :unique_active_signup_per_member, on: :create

  before_save :stamp_status_timestamps

  delegate :fleet_event, to: :fleet_event_slot
  delegate :user, to: :fleet_membership

  def withdrawn?
    status == "withdrawn"
  end

  def confirmed?
    status == "confirmed"
  end

  def tentative?
    status == "tentative"
  end

  def withdraw!
    update!(status: "withdrawn", withdrawn_at: Time.current)
  end

  private def unique_active_signup_per_member
    return if status == "withdrawn"

    existing = FleetEventSignup.where(
      fleet_event_slot_id: fleet_event_slot_id,
      fleet_membership_id: fleet_membership_id
    ).where.not(status: "withdrawn").where.not(id: id)

    if existing.exists?
      errors.add(:fleet_membership_id, :already_signed_up)
    end
  end

  private def stamp_status_timestamps
    if status_changed? && status == "confirmed" && confirmed_at.nil?
      self.confirmed_at = Time.current
    end
    if status_changed? && status == "withdrawn" && withdrawn_at.nil?
      self.withdrawn_at = Time.current
    end
  end
end
