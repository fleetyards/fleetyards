# == Schema Information
#
# Table name: fleet_roles
#
#  id              :uuid             not null, primary key
#  name            :string
#  permanent       :boolean
#  rank            :text
#  resource_access :text
#  slug            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  fleet_id        :uuid             not null
#
# Indexes
#
#  index_fleet_roles_on_fleet_id           (fleet_id)
#  index_fleet_roles_on_fleet_id_and_rank  (fleet_id,rank) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
require "lexorank/rankable"

class FleetRole < ApplicationRecord
  include ResourceAccessConcern

  belongs_to :fleet
  has_many :fleet_memberships,
    dependent: :nullify

  rank!(group_by: :fleet)

  AVAILABLE_PRIVILEGES = [
    "fleet:roles:read",
    "fleet:roles:create",
    "fleet:roles:update",
    "fleet:roles:delete",
    "fleet:roles:manage"
  ].freeze

  def self.all_available_privileges
    [
      Fleet::AVAILABLE_PRIVILEGES,
      FleetMembership::AVAILABLE_PRIVILEGES,
      FleetInviteUrl::AVAILABLE_PRIVILEGES,
      FleetVehicle::AVAILABLE_PRIVILEGES,
      FleetRole::AVAILABLE_PRIVILEGES
    ].flatten.uniq
  end

  validates :name, uniqueness: {case_sensitive: false, scope: :fleet}, presence: true
  validate :resource_access_changed
  validates :resource_access, inclusion: {in: all_available_privileges}

  before_save :update_slugs
  before_create :setup_rank

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:roles:manage"],
    member: ["fleet:roles:read"]
  }.freeze

  def self.preset_privileges
    {
      admin: [
        Fleet::DEFAULT_PRIVILEGES[:admin],
        FleetMembership::DEFAULT_PRIVILEGES[:admin],
        FleetInviteUrl::DEFAULT_PRIVILEGES[:admin],
        FleetVehicle::DEFAULT_PRIVILEGES[:admin],
        FleetRole::DEFAULT_PRIVILEGES[:admin]
      ].flatten.uniq,
      officer: [
        Fleet::DEFAULT_PRIVILEGES[:officer],
        FleetMembership::DEFAULT_PRIVILEGES[:officer],
        FleetInviteUrl::DEFAULT_PRIVILEGES[:officer],
        FleetVehicle::DEFAULT_PRIVILEGES[:officer],
        FleetRole::DEFAULT_PRIVILEGES[:officer]
      ].flatten.uniq,
      member: [
        Fleet::DEFAULT_PRIVILEGES[:member],
        FleetMembership::DEFAULT_PRIVILEGES[:member],
        FleetInviteUrl::DEFAULT_PRIVILEGES[:member],
        FleetVehicle::DEFAULT_PRIVILEGES[:member],
        FleetRole::DEFAULT_PRIVILEGES[:member]
      ].flatten.uniq
    }
  end

  def self.setup_default_roles(fleet)
    fleet.fleet_roles.find_or_create_by!(
      name: "Admin"
    ) do |role|
      role.resource_access = preset_privileges[:admin]
      role.rank = 0
      role.permanent = true
    end

    fleet.fleet_roles.find_or_create_by!(
      name: "Officer"
    ) do |role|
      role.resource_access = preset_privileges[:officer]
      role.rank = 10
    end

    fleet.fleet_roles.find_or_create_by!(
      name: "Member"
    ) do |role|
      role.resource_access = preset_privileges[:member]
      role.rank = 20
    end
  end

  private def setup_rank
    return if rank.present?

    index = fleet.fleet_roles.ranked.index(fleet.fleet_roles.ranked.last)

    return if index < 0

    move_to(index - 1)
  end

  private def resource_access_changed
    if resource_access_changed? && persisted? && permanent?
      errors.add(:resource_access, t("activerecord.errors.models.fleet_role.attributes.resource_access.changed"))
    end
  end

  private def update_slugs
    self.slug = generate_slug(name)
  end
end
