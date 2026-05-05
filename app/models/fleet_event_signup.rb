# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_event_signups
#
#  id                  :uuid             not null, primary key
#  confirmed_at        :datetime
#  notes               :text
#  status              :string           default("confirmed"), not null
#  withdrawn_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_event_id      :uuid             not null
#  fleet_event_slot_id :uuid
#  fleet_membership_id :uuid             not null
#  vehicle_id          :uuid
#
# Indexes
#
#  index_fleet_event_signups_on_fleet_event_id        (fleet_event_id)
#  index_fleet_event_signups_on_fleet_event_slot_id   (fleet_event_slot_id)
#  index_fleet_event_signups_on_fleet_membership_id   (fleet_membership_id)
#  index_fleet_event_signups_unique_active_per_event  (fleet_event_id,fleet_membership_id) UNIQUE WHERE ((status)::text <> 'withdrawn'::text)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_id => fleet_events.id)
#  fk_rails_...  (fleet_event_slot_id => fleet_event_slots.id)
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (vehicle_id => vehicles.id) ON DELETE => nullify
#
class FleetEventSignup < ApplicationRecord
  STATUSES = %w[confirmed tentative interested pending withdrawn].freeze
  MEMBER_REQUESTABLE_STATUSES = %w[confirmed tentative interested].freeze

  belongs_to :fleet_event, touch: true
  belongs_to :fleet_event_slot, touch: true, optional: true
  belongs_to :fleet_membership
  belongs_to :vehicle, optional: true

  validates :status, inclusion: {in: STATUSES}
  validate :unique_active_signup_per_member, on: :create
  validate :slot_not_already_taken, on: :create
  validate :slot_belongs_to_event

  before_validation :assign_event_from_slot
  before_save :stamp_status_timestamps

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

  def interested?
    status == "interested"
  end

  def pending?
    status == "pending"
  end

  def withdraw!
    update!(status: "withdrawn", withdrawn_at: Time.current)
  end

  # Effective approval mode (slot override, falling back to the event default).
  def effective_signup_approval
    fleet_event_slot&.signup_approval.presence ||
      fleet_event&.signup_approval ||
      "direct"
  end

  private def assign_event_from_slot
    return if fleet_event_id.present?
    return if fleet_event_slot.blank?

    self.fleet_event = fleet_event_slot.fleet_event
  end

  private def slot_belongs_to_event
    return if fleet_event_slot.blank? || fleet_event.blank?
    return if fleet_event_slot.fleet_event&.id == fleet_event_id

    errors.add(:fleet_event_slot_id, :wrong_event)
  end

  private def unique_active_signup_per_member
    return if status == "withdrawn"
    return if fleet_event_id.blank?

    existing = FleetEventSignup.where(
      fleet_event_id: fleet_event_id,
      fleet_membership_id: fleet_membership_id
    ).where.not(status: "withdrawn").where.not(id: id)

    if existing.exists?
      errors.add(:fleet_membership_id, :already_signed_up)
    end
  end

  private def slot_not_already_taken
    return if status == "withdrawn"
    return if fleet_event_slot_id.blank?

    taken = FleetEventSignup
      .where(fleet_event_slot_id: fleet_event_slot_id)
      .where.not(status: "withdrawn")
      .where.not(id: id)
      .where.not(fleet_membership_id: fleet_membership_id)

    if taken.exists?
      errors.add(:fleet_event_slot_id, :already_taken)
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
