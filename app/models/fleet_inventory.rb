# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_inventories
#
#  id           :uuid             not null, primary key
#  description  :text
#  image_preset :string
#  location     :string
#  managed_by   :uuid
#  name         :string           not null
#  slug         :string           not null
#  visibility   :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  fleet_id     :uuid             not null
#
# Indexes
#
#  index_fleet_inventories_on_fleet_id_and_lower_name  (fleet_id, lower((name)::text)) UNIQUE
#  index_fleet_inventories_on_fleet_id_and_managed_by  (fleet_id,managed_by)
#  index_fleet_inventories_on_fleet_id_and_slug        (fleet_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (managed_by => users.id)
#
class FleetInventory < ApplicationRecord
  include ActiveStorageVariants
  include InventoryStock

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 30

  belongs_to :fleet, touch: true
  belongs_to :manager, class_name: "User", foreign_key: :managed_by, optional: true

  inventory_items_association :fleet_inventory_items
  positions_association :fleet_inventory_positions

  has_one_attached :image
  validates :image, no_vector_image: true

  enum :visibility, {members_only: 0, officers_only: 1}

  validates :name, presence: true, uniqueness: {case_sensitive: false, scope: :fleet_id}

  validate :manager_belongs_to_fleet

  AVAILABLE_PRIVILEGES = [
    "fleet:inventories:read",
    "fleet:inventories:create",
    "fleet:inventories:update",
    "fleet:inventories:delete",
    "fleet:inventories:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:inventories:manage"],
    member: ["fleet:inventories:read"]
  }.freeze

  # Who counts as an officer for an officers-only store. No officer privilege
  # exists -- the roles enum draws its lines per resource -- so the inventory
  # manage set stands in for one, which is what `DEFAULT_PRIVILEGES` seeds the
  # officer role with anyway.
  OFFICER_PRIVILEGES = ["fleet:manage", "fleet:inventories:manage"].freeze

  # Whether a member may see this inventory at all: its name and description
  # included, not only its contents.
  #
  # One definition, called by `FleetInventoryPolicy` for the endpoints and by
  # `Inventories::TransferAuthorizer` for the two ends of a transfer.
  def visible_to?(membership)
    return true unless officers_only?
    return false if membership.blank?
    return true if membership.has_access?(OFFICER_PRIVILEGES)

    # The manager reaches the store they are answerable for: `managed_by` names
    # the member accountable for it, and `manager_belongs_to_fleet` already
    # keeps that to someone in the fleet.
    #
    # This lifts the officers-only bar, not the baseline read privilege. A
    # manager whose role carries no inventory access at all still sees nothing
    # -- the officers-only distinction never arises for them.
    managed_by.present? && managed_by == membership.user_id
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug fleet_id visibility created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet manager]
  end

  def ledger_attributes_for(user)
    {added_by: user&.id}
  end

  # Pending invites, open requests and declined applicants all live in the same
  # table as the roster, so an unfiltered member list offers people who never
  # joined. The picker asks for accepted memberships; this keeps a request that
  # names anyone else from storing them as the manager.
  #
  # Only on a change: nothing clears `managed_by` when a manager leaves the
  # fleet, so a row that already names a former member has to stay editable --
  # renaming such an inventory must not fail over a field the edit never touched.
  private def manager_belongs_to_fleet
    return if managed_by.blank?
    return unless will_save_change_to_managed_by?
    return if fleet&.fleet_memberships&.kept&.exists?(user_id: managed_by, aasm_state: "accepted")

    errors.add(:managed_by, :not_a_member)
  end
end
