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
  AVAILABLE_PRIVILEGES = [
    "fleet:manage",
    "fleet:update",
    "fleet:members",
    "fleet:members:create",
    "fleet:members:update",
    "fleet:members:delete",
    "fleet:invites",
    "fleet:invites:create",
    "fleet:invites:update",
    "fleet:invites:delete",
    "fleet:promotions",
    "fleet:squadrons",
    "fleet:squadrons:create",
    "fleet:squadrons:update",
    "fleet:squadrons:delete"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: ["fleet:manage"],
    officer: ["fleet:members", "fleet:invites", "fleet:promotions", "fleet:squadrons"],
    member: []
  }.freeze

  belongs_to :fleet
  has_many :fleet_memberships

  rank!(group_by: :fleet)

  validates :name, uniqueness: {case_sensitive: false, scope: :fleet}, presence: true
  validate :resource_access_changed
  validates :resource_access, inclusion: {in: AVAILABLE_PRIVILEGES}

  serialize :resource_access, coder: YAML

  before_save :update_slugs

  private def resource_access_changed
    if resource_access_changed? && persisted? && permanent?
      errors.add(:resource_access, t("activerecord.errors.models.fleet_role.attributes.resource_access.changed"))
    end
  end

  private def update_slugs
    self.slug = generate_slug(name)
  end
end
