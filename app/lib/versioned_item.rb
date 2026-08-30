# frozen_string_literal: true

# The catalogues paper_trail watches, and what an admin has to be allowed to see
# before a version of one is readable.
#
# An endpoint that took any `item_type` from the request would let a caller read
# -- and revert -- a row in any table paper_trail ever touched, so the list is
# explicit rather than derived from the class name it was handed.
#
# Six of the ten have no admin page and no policy of their own. They are
# authorised through the record that does: a fleet's roles, memberships and
# inventories through the fleet, an inventory through whoever holds it. That
# holder is polymorphic, which is why the policy is looked up from the record
# the walk lands on rather than from the item type it started at.
class VersionedItem
  # paper_trail 17 defaults `on` to %i[create update destroy touch], and a touch
  # can never record `object_changes` -- rails' `touch` skips dirty-tracking, so
  # `Events::Update#record_object_changes?` returns false for one. It files the
  # version anyway, which leaves a row whose changeset is empty.
  #
  # Fleet has seven `belongs_to :fleet, touch: true` children, so an event, a
  # membership or a role write files a fleet version that says nothing: 572,735
  # of its 573,199 update versions are that, against 464 real edits.
  RECORDED_EVENTS = %i[create update destroy].freeze

  ROOTS = {
    "Component" => [],
    "Fleet" => [],
    "FleetInventory" => [:fleet],
    "FleetInventoryItem" => [:fleet_inventory, :fleet],
    "FleetMembership" => [:fleet],
    "FleetRole" => [:fleet],
    "Inventory" => [:holder],
    "InventoryItem" => [:inventory, :holder],
    "Model" => [],
    "ModelModule" => []
  }.freeze

  TYPES = ROOTS.keys.freeze

  POLICIES = {
    "Component" => ::Admin::ComponentPolicy,
    "Fleet" => ::Admin::FleetPolicy,
    "Model" => ::Admin::ModelPolicy,
    "ModelModule" => ::Admin::ModelModulePolicy,
    "User" => ::Admin::UserPolicy
  }.freeze

  def self.supported?(item_type)
    TYPES.include?(item_type)
  end

  # A missing or unlisted `item_type` is answered the same way a missing id is:
  # there is no such item to read a history for.

  def self.find(item_type, item_id)
    raise ActiveRecord::RecordNotFound unless supported?(item_type)

    item_type.constantize.find(item_id)
  end

  # The record whose policy decides, and that policy. A chain that runs into a
  # `nil` -- an inventory whose holder was deleted -- has no root to ask, and a
  # root of a class nobody wrote an admin policy for is the same answer: no.
  def self.authorization_root(item)
    root = ROOTS.fetch(item.class.name, nil)&.reduce(item) { |record, association| record&.public_send(association) }

    return if root.blank?

    policy = POLICIES[root.class.name]

    return if policy.blank?

    [root, policy]
  end
end
