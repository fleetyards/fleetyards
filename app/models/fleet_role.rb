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
#  discord_role_id :string
#  fleet_id        :uuid             not null
#
# Indexes
#
#  index_fleet_roles_on_fleet_id_and_rank  (fleet_id,rank) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
require "lexorank/rankable"

class FleetRole < ApplicationRecord
  include ResourceAccessConcern

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  belongs_to :fleet, touch: true
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

  PRIVILEGE_GROUPS = {
    "fleet" => Fleet::AVAILABLE_PRIVILEGES,
    "memberships" => FleetMembership::AVAILABLE_PRIVILEGES,
    "invites" => FleetInviteUrl::AVAILABLE_PRIVILEGES,
    "vehicles" => FleetVehicle::AVAILABLE_PRIVILEGES,
    "roles" => FleetRole::AVAILABLE_PRIVILEGES,
    "inventories" => FleetInventory::AVAILABLE_PRIVILEGES,
    "missions" => Mission::AVAILABLE_PRIVILEGES,
    "events" => FleetEvent::AVAILABLE_PRIVILEGES,
    "notifications" => FleetNotificationSetting::AVAILABLE_PRIVILEGES
  }.freeze

  def self.privilege_groups
    PRIVILEGE_GROUPS.map do |key, privileges|
      {
        key: key,
        privileges: privileges,
        manage_privilege: privileges.find { |privilege| privilege.end_with?(":manage") }
      }
    end
  end

  def self.all_available_privileges
    PRIVILEGE_GROUPS.values.flatten.uniq
  end

  validates :name, uniqueness: {case_sensitive: false, scope: :fleet}, presence: true
  validate :resource_access_changed
  validates :resource_access, inclusion: {in: all_available_privileges}

  before_save :update_slugs
  before_create :setup_rank
  before_destroy :check_if_can_be_destroyed, prepend: true

  # Narrowed to this rank: a single mapping cannot affect anyone else.
  after_commit :backfill_discord_member_roles, if: :saved_change_to_discord_role_id?

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
        FleetRole::DEFAULT_PRIVILEGES[:admin],
        FleetInventory::DEFAULT_PRIVILEGES[:admin],
        Mission::DEFAULT_PRIVILEGES[:admin],
        FleetEvent::DEFAULT_PRIVILEGES[:admin]
      ].flatten.uniq,
      officer: [
        Fleet::DEFAULT_PRIVILEGES[:officer],
        FleetMembership::DEFAULT_PRIVILEGES[:officer],
        FleetInviteUrl::DEFAULT_PRIVILEGES[:officer],
        FleetVehicle::DEFAULT_PRIVILEGES[:officer],
        FleetRole::DEFAULT_PRIVILEGES[:officer],
        FleetInventory::DEFAULT_PRIVILEGES[:officer],
        Mission::DEFAULT_PRIVILEGES[:officer],
        FleetEvent::DEFAULT_PRIVILEGES[:officer]
      ].flatten.uniq,
      member: [
        Fleet::DEFAULT_PRIVILEGES[:member],
        FleetMembership::DEFAULT_PRIVILEGES[:member],
        FleetInviteUrl::DEFAULT_PRIVILEGES[:member],
        FleetVehicle::DEFAULT_PRIVILEGES[:member],
        FleetRole::DEFAULT_PRIVILEGES[:member],
        FleetInventory::DEFAULT_PRIVILEGES[:member],
        Mission::DEFAULT_PRIVILEGES[:member],
        FleetEvent::DEFAULT_PRIVILEGES[:member]
      ].flatten.uniq
    }
  end

  def self.setup_default_roles!(fleet)
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

  # Nullifying would leave the members silently without any privileges, so a
  # role in use has to be emptied first. Skipped when the whole fleet is going
  # away -- Fleet destroys its roles before its memberships. Prepended because
  # the :nullify callback is registered first and would clear the rows we check.
  private def check_if_can_be_destroyed
    return if destroyed_by_association
    return unless fleet_memberships.kept.exists?

    errors.add(:base, I18n.t("activerecord.errors.models.fleet_role.attributes.base.cannot_destroy_with_members"))
    throw(:abort)
  end

  private def resource_access_changed
    if resource_access_changed? && persisted? && permanent?
      errors.add(:resource_access, t("activerecord.errors.models.fleet_role.attributes.resource_access.changed"))
    end
  end

  private def update_slugs
    self.slug = generate_slug(name)
  end

  private def backfill_discord_member_roles
    ::Discord::BackfillFleetMemberRolesJob.perform_async(fleet_id, id)
  end
end
