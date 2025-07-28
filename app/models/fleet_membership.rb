# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_memberships
#
#  id                :uuid             not null, primary key
#  aasm_state        :string
#  accepted_at       :datetime
#  declined_at       :datetime
#  hide_ships        :boolean          default(FALSE)
#  invited_at        :datetime
#  invited_by        :uuid
#  primary           :boolean          default(FALSE)
#  requested_at      :datetime
#  role              :integer
#  ships_filter      :integer          default("all")
#  used_invite_token :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_id          :uuid
#  fleet_role_id     :uuid
#  hangar_group_id   :uuid
#  user_id           :uuid
#
# Indexes
#
#  index_fleet_memberships_on_fleet_role_id         (fleet_role_id)
#  index_fleet_memberships_on_user_id_and_fleet_id  (user_id,fleet_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_role_id => fleet_roles.id)
#
class FleetMembership < ApplicationRecord
  include AASM

  attr_accessor :update_reason, :update_reason_description, :author_id

  AVAILABLE_PRIVILEGES = [
    "fleet:memberships:read",
    "fleet:memberships:create",
    "fleet:memberships:update",
    "fleet:memberships:delete",
    "fleet:memberships:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:memberships:manage"],
    member: ["fleet:memberships:read"]
  }.freeze

  has_paper_trail meta: {
    author_id: :author_id,
    reason: :update_reason,
    reason_description: :update_reason_description
  }

  belongs_to :fleet, touch: true
  belongs_to :fleet_role, optional: true
  belongs_to :user, touch: true

  paginates_per 30

  enum :ships_filter,
    {all: 0, hangar_group: 1, hide: 2},
    prefix: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "aasm_state", "accepted_at", "created_at", "declined_at", "fleet_id", "hangar_group_id",
      "hide_ships", "id", "id_value", "invited_at", "invited_by", "name", "primary", "requested_at",
      "role", "ships_filter", "updated_at", "used_invite_token", "user_id", "username"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["fleet", "user"]
  end

  validate_enum_attributes :ships_filter, :role

  validates :user_id, uniqueness: {scope: :fleet_id}

  DEFAULT_SORTING_PARAMS = ["created_at desc", "accepted_at desc"]
  ALLOWED_SORTING_PARAMS = [
    "userRsiHandle asc", "userRsiHandle desc", "userUsername asc", "userUsername desc",
    "createdAt asc", "createdAt desc", "acceptedAt asc", "acceptedAt desc"
  ]

  enum role: {admin: 0, officer: 1, member: 2}

  ransack_alias :username, :user_username
  ransack_alias :name, :user_username
  ransack_alias :role, :fleet_role_name

  before_validation :set_default_ships_filter
  after_create :broadcast_create
  after_destroy :broadcast_destroy, :remove_fleet_vehicles
  after_save :set_primary
  after_create_commit :schedule_setup_fleet_vehicles
  after_update_commit :schedule_update_fleet_vehicles
  after_commit :broadcast_update
  before_destroy :check_if_can_be_destroyed

  delegate :has_access?, to: :fleet_role

  def check_if_can_be_destroyed
    return unless fleet_role&.permanent?

    errors.add(:base, I18n.t("activerecord.errors.models.fleet_membership.attributes.base.cannot_destroy_from_permanent_role"))
    throw(:abort)
  end

  aasm timestamps: true, whiny_transitions: false do
    state :created, initial: true
    state :invited
    state :requested
    state :accepted
    state :declined

    event :invite, after_commit: :notify_invited_user do
      transitions from: :created, to: :invited
    end

    event :request, after_commit: :notify_fleet_admins do
      transitions from: :created, to: :requested
    end

    event :accept_invitation, after_commit: :on_accept_invitation do
      transitions from: :invited, to: :accepted
    end

    event :accept_request, after_commit: :on_accept_request do
      transitions from: :requested, to: :accepted
    end

    event :decline do
      transitions from: %i[invited requested], to: :declined
    end
  end

  def set_default_ships_filter
    return if ships_filter.present?

    self.ships_filter = "all"
  end

  def schedule_setup_fleet_vehicles
    Updater::FleetMembershipVehiclesSetupJob.perform_async(id)
  end

  def schedule_update_fleet_vehicles
    Updater::FleetMembershipVehiclesUpdateJob.perform_async(id)
  end

  def setup_fleet_vehicles
    return unless accepted?
    return if ships_filter_hide?

    user.vehicles.visible.each do |vehicle|
      update_fleet_vehicle(vehicle)
    end
  end

  def update_fleet_vehicles
    return unless accepted?

    if ships_filter_hide?
      remove_fleet_vehicles
    else
      user.vehicles.visible.each do |vehicle|
        update_fleet_vehicle(vehicle)
      end
    end
  end

  def remove_fleet_vehicles
    FleetVehicle.where(fleet_id:, vehicle_id: user.vehicle_ids).destroy_all
  end

  def update_fleet_vehicle(vehicle)
    case ships_filter
    when "all"
      update_fleet_vehicle_for_all(vehicle)
    when "hangar_group"
      update_fleet_vehicle_for_hangar_group(vehicle)
    else
      FleetVehicle.find_by(fleet_id:, vehicle_id: vehicle.id)&.destroy
    end
  end

  def update_fleet_vehicle_for_all(vehicle)
    if vehicle.wanted?
      FleetVehicle.find_by(fleet_id:, vehicle_id: vehicle.id)&.destroy
    else
      FleetVehicle.find_or_create_by(fleet_id:, vehicle_id: vehicle.id)
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def update_fleet_vehicle_for_hangar_group(vehicle)
    parent_vehicle = Vehicle.find_by(id: vehicle.vehicle_id) if vehicle.loaner?
    hangar_group_ids = (vehicle.hangar_group_ids + (parent_vehicle&.hangar_group_ids || []))

    if hangar_group_ids.include?(hangar_group_id)
      FleetVehicle.find_or_create_by(fleet_id:, vehicle_id: vehicle.id)
    else
      FleetVehicle.find_by(fleet_id:, vehicle_id: vehicle.id)&.destroy
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def set_primary
    return unless primary?

    # rubocop:disable Rails/SkipsModelValidations
    FleetMembership.where(user_id:, primary: true)
      .where.not(id:)
      .update_all(primary: false)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def notify_invited_user
    return unless invited?

    FleetMembershipMailer.new_invite(user.email, user.username, fleet).deliver_later
  end

  def on_accept_invitation
    notify_fleet_admins

    fleet.fleet_memberships.find_each do |member|
      FleetVehiclesChannel.broadcast_to(member.user, to_json)
    end
  end

  def notify_fleet_admins
    return unless requested? || accepted?

    emails = fleet.fleet_memberships.where(role: :admin).map { |admin| admin.user.email }

    if requested?
      FleetMembershipMailer.member_requested(emails, user.username, fleet).deliver_later
    elsif accepted?
      FleetMembershipMailer.member_accepted(emails, user.username, fleet).deliver_later
    end
  end

  def on_accept_request
    notify_new_member

    fleet.fleet_memberships.find_each do |member|
      FleetVehiclesChannel.broadcast_to(member.user, to_json)
    end
  end

  def notify_new_member
    return unless accepted?

    FleetMembershipMailer.fleet_accepted(user.email, user.username, fleet).deliver_later
  end

  def broadcast_update
    fleet.fleet_memberships.find_each do |member|
      FleetMembersChannel.broadcast_to(member.user, to_json)

      next unless ships_filter_changed?

      FleetVehiclesChannel.broadcast_to(member.user, to_json)
    end
  end

  def broadcast_create
    fleet.fleet_memberships.find_each do |member|
      FleetMembersChannel.broadcast_to(member.user, to_json)
    end
  end

  def broadcast_destroy
    fleet.fleet_memberships.find_each do |member|
      FleetMembersChannel.broadcast_to(member.user, to_json)
      FleetVehiclesChannel.broadcast_to(member.user, to_json)
    end
  end

  def promote
    return if next_fleet_role == fleet_role || next_fleet_role.nil?

    update(fleet_role: next_fleet_role)
  end

  def demote
    return if fleet_role.permanent? && fleet_role.fleet_memberships.count == 1
    return if prev_fleet_role == fleet_role || prev_fleet_role.nil?

    update(fleet_role: prev_fleet_role)
  end

  def next_fleet_role
    return if fleet_role.nil?

    index = fleet.fleet_roles.ranked.index(fleet_role)

    return if index - 1 < 0

    fleet.fleet_roles[index - 1]
  end

  def prev_fleet_role
    return if fleet_role.nil?

    index = fleet.fleet_roles.ranked.index(fleet_role)
    fleet.fleet_roles[index + 1]
  end

  def to_json(*_args)
    to_jbuilder_json
  end
end
