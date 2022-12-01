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
#  ships_filter      :integer          default("purchased")
#  used_invite_token :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_id          :uuid
#  hangar_group_id   :uuid
#  user_id           :uuid
#
# Indexes
#
#  index_fleet_memberships_on_user_id_and_fleet_id  (user_id,fleet_id) UNIQUE
#
class FleetMembership < ApplicationRecord
  include AASM

  belongs_to :fleet, touch: true
  belongs_to :user, touch: true

  paginates_per 30

  enum ships_filter: { purchased: 0, hangar_group: 1, hide: 2 }, _prefix: true

  enum role: { admin: 0, officer: 1, member: 2 }
  ransacker :role, formatter: proc { |v| FleetMembership.roles[v] } do |parent|
    parent.table[:role]
  end

  validates :user_id, uniqueness: { scope: :fleet_id }

  ransack_alias :username, :user_username
  ransack_alias :name, :user_username

  after_create :broadcast_create, :setup_fleet_vehicles
  after_update :update_fleet_vehicles
  after_destroy :broadcast_destroy, :teardown_fleet_vehicles
  after_save :set_primary
  after_commit :broadcast_update

  aasm timestamps: true do
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

  def setup_fleet_vehicles
    return if ships_filter_hide?

    user.vehicles.each do |vehicle|
      add_fleet_vehicle(vehicle)
    end
  end

  def update_fleet_vehicles
    return unless ships_filter_changed?

    teardown_fleet_vehicles

    setup_fleet_vehicles
  end

  def teardown_fleet_vehicles
    fleet.fleet_vehicles.where(vehicle_id: user.vehicle_ids).destroy_all
  end

  def add_fleet_vehicle(vehicle)
    return if ships_filter_hide?

    return if ships_filter_purchased? && !vehicle.purchased?

    parent_vehicle = Vehicle.find_by(id: vehicle.vehicle_id) if vehicle.loaner?
    hangar_group_ids = (vehicle.hangar_group_ids + (parent_vehicle&.hangar_group_ids || []))
    return if ships_filter_hangar_group? && hangar_group_ids.exclude?(hangar_group_id)

    FleetVehicle.create(
      fleet_id: fleet_id,
      vehicle_id: vehicle.id
    )
  end

  def set_primary
    return unless primary?

    # rubocop:disable Rails/SkipsModelValidations
    FleetMembership.where(user_id: user_id, primary: true)
      .where.not(id: id)
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
    return if admin?

    if officer?
      update(role: :admin)
    else
      update(role: :officer)
    end
  end

  def demote
    return if member?

    if admin?
      update(role: :officer)
    else
      update(role: :member)
    end
  end

  def to_json(*_args)
    to_jbuilder_json
  end
end
