# frozen_string_literal: true

class FleetEventSignup < ApplicationRecord
  STATUSES = %w[confirmed tentative interested pending invited withdrawn].freeze
  MEMBER_REQUESTABLE_STATUSES = %w[confirmed tentative interested].freeze
  # Slot-bound signups must commit to the slot — only fully confirmed
  # signups, those still awaiting admin approval, or a member a squadron's
  # flight invited and who has yet to answer are allowed there.
  SLOT_BOUND_STATUSES = %w[confirmed pending invited withdrawn].freeze

  belongs_to :fleet_event, touch: true
  belongs_to :fleet_event_slot, touch: true, optional: true
  belongs_to :fleet_membership
  belongs_to :vehicle, optional: true

  validates :status, inclusion: {in: STATUSES}
  validate :slot_exists, if: :fleet_event_slot_changing?
  validate :vehicle_owned_by_member, if: :vehicle_changing?
  validate :unique_active_signup_per_member, if: -> { new_record? || will_save_change_to_team_seat? }
  validate :slot_not_already_taken, if: :entering_slot?
  validate :membership_still_kept, if: :claims_seat?
  validate :slot_belongs_to_event
  validate :slot_bound_status_allowed

  before_validation :assign_event_from_slot
  before_validation :mark_team_seat
  before_save :mark_team_seat
  before_save :stamp_status_timestamps

  # A member leaving a slot that was offered down a list hands it to the next
  # one on it.
  after_update_commit :hand_slot_on, if: :left_slot?
  after_destroy_commit -> { hand_slot_on(fleet_event_slot_id) }, if: -> { fleet_event_slot_id.present? && !withdrawn? }

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

  def invited?
    status == "invited"
  end

  CONFLICT_INDEX_ERRORS = {
    "index_fleet_event_signups_unique_active_per_slot" => [:fleet_event_slot_id, :already_taken],
    "index_fleet_event_signups_unique_active_per_event" => [:fleet_membership_id, :already_signed_up],
    "index_fleet_event_signups_unique_active_team_seat_per_event" => [:fleet_membership_id, :already_signed_up]
  }.freeze
  CONFLICT_FOREIGN_KEYS = %w[fleet_event_slot_id vehicle_id].freeze

  # Validation reads before the write, so a slot claimed, or a slot or vehicle
  # deleted, by a request running alongside still reaches the database, and an
  # index or foreign key rejects the loser. Give it the validation error the
  # sequential case already gets, rather than a 500.
  #
  # The savepoint is what lets a caller wrap this in a transaction of its own:
  # the violation aborts whichever transaction it happens in, so without one
  # the rescue would hand back a connection whose next statement fails.
  def save_without_conflict
    self.class.transaction(requires_new: true) { save }
  rescue ActiveRecord::RecordNotUnique => e
    attribute, type = CONFLICT_INDEX_ERRORS.find { |index, _| e.message.include?(index) }&.last
    raise if attribute.nil?

    errors.add(attribute, type)
    false
  rescue ActiveRecord::InvalidForeignKey => e
    attribute = CONFLICT_FOREIGN_KEYS.find { |column| e.message.include?("Key (#{column})=") }
    raise if attribute.nil?

    errors.add(attribute, :required)
    false
  end

  def update_without_conflict(attributes)
    assign_attributes(attributes)
    save_without_conflict
  end

  def withdraw!(validate: true)
    assign_attributes(status: "withdrawn", withdrawn_at: Time.current)
    save!(validate:)
  end

  # A recurring signup is keyed by day, so its date alone cannot tell whether
  # today's occurrence has already started.
  def occurrence_started?
    return fleet_event.active? || fleet_event.starts_at <= Time.current unless fleet_event.recurring?
    return false if occurrence_date.nil?
    return occurrence_date < Date.current unless occurrence_date == Date.current
    return true if fleet_event.active?

    starts_at = fleet_event.occurrence_starts_at(occurrence_date)
    starts_at.present? && starts_at <= Time.current
  end

  # Effective approval mode (slot override, falling back to the event default).
  def effective_signup_approval
    fleet_event_slot&.signup_approval.presence ||
      fleet_event&.signup_approval ||
      "direct"
  end

  # A seat on the team rather than on one of its ships, like the lead's, is a
  # role on top of whatever the member flies: it is a signup of its own and
  # leaves the member free to take a ship seat or wait in the pool too.
  def self.team_seat_slot?(slot)
    slot&.slottable_type == "FleetEventTeam"
  end

  # A member holding a team seat and a ship seat is one person at the event.
  def self.attendee_count
    distinct.pluck(:fleet_membership_id, :occurrence_date).size
  end

  # The signups that compete with one in this kind of slot; a pool signup
  # competes with a ship seat, never with a team seat.
  def self.same_kind_as(slot)
    where(team_seat: team_seat_slot?(slot))
  end

  private def mark_team_seat
    self.team_seat = self.class.team_seat_slot?(fleet_event_slot)
  end

  private def assign_event_from_slot
    return if fleet_event_id.present?
    return if fleet_event_slot.blank?

    self.fleet_event = fleet_event_slot.fleet_event
  end

  # An optional belongs_to never checks that its record exists, so an id left
  # over from a deleted slot or vehicle would only fail at the foreign key.
  private def slot_exists
    errors.add(:fleet_event_slot_id, :required) unless FleetEventSlot.exists?(fleet_event_slot_id)
  end

  private def vehicle_owned_by_member
    owner_id = Vehicle.where(id: vehicle_id).pick(:user_id)

    if owner_id.nil?
      errors.add(:vehicle_id, :required)
    elsif fleet_membership.present? && owner_id != fleet_membership.user_id
      errors.add(:vehicle_id, :not_owned)
    end
  end

  private def fleet_event_slot_changing?
    fleet_event_slot_id.present? && (new_record? || will_save_change_to_fleet_event_slot_id?)
  end

  # A save that puts this signup in a slot: a new signup, an admin assign, a
  # promotion out of the event pool or a revived withdrawal. A status change in
  # place, like an approval, does not, so a slot that is already double-booked
  # can still be sorted out.
  private def entering_slot?
    return false if fleet_event_slot_id.blank? || withdrawn?

    new_record? || will_save_change_to_fleet_event_slot_id? || status_in_database == "withdrawn"
  end

  private def vehicle_changing?
    vehicle_id.present? && (new_record? || will_save_change_to_vehicle_id?)
  end

  private def slot_belongs_to_event
    return if fleet_event_slot.blank? || fleet_event.blank?
    return if fleet_event_slot.fleet_event&.id == fleet_event_id

    errors.add(:fleet_event_slot_id, :wrong_event)
  end

  private def slot_bound_status_allowed
    return if fleet_event_slot_id.blank?
    return if SLOT_BOUND_STATUSES.include?(status)

    errors.add(:status, :invalid_for_slot)
  end

  private def unique_active_signup_per_member
    return if status == "withdrawn"
    return if fleet_event_id.blank?

    # For recurring events signups are scoped to a specific occurrence date,
    # so the same member can sign up for "next Thursday" and "the Thursday
    # after". For one-off events occurrence_date is nil on both sides.
    existing = FleetEventSignup.where(
      fleet_event_id: fleet_event_id,
      fleet_membership_id: fleet_membership_id,
      occurrence_date: occurrence_date,
      team_seat: team_seat
    ).where.not(status: "withdrawn").where.not(id: id)

    if existing.exists?
      errors.add(:fleet_membership_id, :already_signed_up)
    end
  end

  private def slot_not_already_taken
    return if status == "withdrawn"
    return if fleet_event_slot_id.blank?

    # For recurring events a slot can host different members across
    # different occurrences. A signup conflicts only if another active
    # signup holds the same slot on the same occurrence (or, for one-off
    # events, occurrence_date is nil on both sides).
    taken = FleetEventSignup
      .where(fleet_event_slot_id: fleet_event_slot_id, occurrence_date: occurrence_date)
      .where.not(status: "withdrawn")
      .where.not(id: id)
      .where.not(fleet_membership_id: fleet_membership_id)

    if taken.exists?
      errors.add(:fleet_event_slot_id, :already_taken)
    end
  end

  # A departing member's seats are withdrawn after the discard, so a signup
  # still in flight, new or promoted from a copy loaded before the cleanup,
  # would slip past it. A shared lock on the membership row orders the two:
  # this either sees the discard or commits before the cleanup reads.
  private def membership_still_kept
    return if fleet_membership_id.blank?

    discarded_at = FleetMembership.lock("FOR SHARE").where(id: fleet_membership_id).pick(:discarded_at)
    errors.add(:fleet_membership_id, :not_a_member) if discarded_at.present?
  end

  # A departed member keeps only signups for events already under way, so a
  # change there is a correction; before that, reviving one retakes a seat.
  private def claims_seat?
    return false if withdrawn?
    return true if new_record?
    return false unless will_save_change_to_status? || will_save_change_to_fleet_event_slot_id?

    !occurrence_started?
  end

  private def left_slot?
    previous_slot_id.present? &&
      (saved_change_to_fleet_event_slot_id? || (saved_change_to_status? && withdrawn?))
  end

  private def previous_slot_id
    saved_change_to_fleet_event_slot_id? ? fleet_event_slot_id_before_last_save : fleet_event_slot_id
  end

  private def hand_slot_on(slot_id = previous_slot_id)
    return unless FleetEventSlotCandidate.exists?(fleet_event_slot_id: slot_id)

    FleetEvents::SlotInvites.pass_on!(slot_id, fleet_membership_id)
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
