# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_memberships
#
#  id                  :uuid             not null, primary key
#  aasm_state          :string
#  accepted_at         :datetime
#  declined_at         :datetime
#  hide_ships          :boolean          default(FALSE)
#  invited_at          :datetime
#  invited_by          :uuid
#  primary             :boolean          default(FALSE)
#  requested_at        :datetime
#  role                :integer
#  ships_filter        :integer          default("purchased")
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_id            :uuid
#  fleet_invite_url_id :uuid
#  hangar_group_id     :uuid
#  user_id             :uuid
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

  after_save :set_primary

  aasm do
    state :created, initial: true
    state :invited
    state :requested
    state :accepted
    state :declined

    event :invite do
      transitions from: :created, to: :invited, after_commit: :notify_invited_user
    end

    event :request do
      transitions from: :created, to: :requested, after_commit: :notify_fleet_admin
    end

    event :accept_invitation do
      transitions from: :invited, to: :accepted, after_commit: :notify_fleet_admin
    end

    event :accept_request do
      transitions from: :requested, to: :accepted, after_commit: :notify_new_member
    end

    event :decline do
      transitions from: %i[invited requested], to: :declined
    end
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

    FleetMembershipMailer.new_invite(user.email, fleet).deliver_later
  end

  def notify_fleet_admin
    return unless requested? || accepted?

    fleet.fleet_memberships.where(role: :admin).find_each do |admin|
      if requested?
        FleetMembershipMailer.member_requested(admin.user.email, fleet).deliver_later
      elsif accepted?
        FleetMembershipMailer.member_accepted(admin.user.email, fleet).deliver_later
      end
    end
  end

  def notify_new_member
    return unless accepted?

    FleetMembershipMailer.fleet_accepted(user.email, fleet).deliver_later
  end

  def visible_vehicle_ids(filters = nil)
    return [] if visible_vehicles.blank?

    scope = visible_vehicles
    scope = scope.where(filters) if filters.present?
    scope.pluck(:id)
  end

  def visible_model_ids(filters = nil)
    return [] if visible_vehicles.blank?

    scope = visible_vehicles
    scope = scope.where(filters) if filters.present?
    scope.pluck(:model_id)
  end

  def visible_vehicles
    return if ships_filter_hide?

    scope = user.vehicles.where(hidden: false)
    scope = scope.includes(:task_forces).where(task_forces: { hangar_group_id: hangar_group_id }) if ships_filter_hangar_group? && hangar_group_id.present?
    scope = scope.purchased if ships_filter_purchased?
    scope
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
end
