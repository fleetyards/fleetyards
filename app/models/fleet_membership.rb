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

  enum ships_filter: {all: 0, hangar_group: 1, hide: 2}, _prefix: true

  enum role: {admin: 0, officer: 1, member: 2}
  ransacker :role, formatter: proc { |v| FleetMembership.roles[v] } do |parent|
    parent.table[:role]
  end

  validates :user_id, uniqueness: {scope: :fleet_id}

  ransack_alias :username, :user_username
  ransack_alias :name, :user_username

  after_create :broadcast_create
  after_destroy :broadcast_destroy, :remove_fleet_vehicles
  after_save :set_primary
  after_create_commit :schedule_setup_fleet_vehicles
  after_update_commit :schedule_update_fleet_vehicles
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
