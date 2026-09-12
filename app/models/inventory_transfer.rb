# frozen_string_literal: true

# Stock moving between two inventories as one recorded event.
#
# One table for all six movements, including the two that cross the user and
# fleet schemas, so the source and the destination are each one of two types --
# hence the pairs of nullable foreign keys and the `#source` / `#destination`
# readers over them. Nothing above this model deals in four columns.
#
# A transfer has no line rows. Its lines are the ledger entries it wrote:
# withdrawals on the source when it was sent, deposits at the destination when
# it was accepted, or deposits back into the source when it was refused. Nothing
# is ever deleted to undo one.
class InventoryTransfer < ApplicationRecord
  include AASM

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 30

  # How long a pending transfer waits before the goods go home by themselves.
  # Escrowed stock must not be able to sit in limbo indefinitely.
  DEFAULT_TTL = 14.days

  # What one recipient may have waiting at once. The thing that stops a stranger
  # filling an inbox; see `Inventories::TransferGate`.
  OUTSTANDING_LIMIT = 25

  belongs_to :source_inventory, class_name: "Inventory", optional: true
  belongs_to :source_fleet_inventory, class_name: "FleetInventory", optional: true
  belongs_to :destination_inventory, class_name: "Inventory", optional: true
  belongs_to :destination_fleet_inventory, class_name: "FleetInventory", optional: true

  belongs_to :recipient, class_name: "User", optional: true
  belongs_to :recipient_fleet, class_name: "Fleet", optional: true

  belongs_to :initiated_by, class_name: "User", optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  has_many :inventory_items, dependent: :nullify
  has_many :fleet_inventory_items, dependent: :nullify
  has_many :reports, class_name: "InventoryTransferReport", dependent: :destroy

  validate :exactly_one_source
  validate :at_most_one_destination
  validate :at_most_one_recipient
  validate :has_a_target
  validate :destination_is_not_the_source

  scope :pending_for_user, ->(user) { pending.where(recipient: user) }
  scope :pending_for_fleet, ->(fleet) { pending.where(recipient_fleet: fleet) }

  # `whiny_transitions: false` matches the other state machines here. The four
  # terminal states are distinct rather than one `closed` with a reason column,
  # because who is told, and what they are told, differs per outcome -- and the
  # inbox filters on it.
  #
  # An immediate transfer never passes through `pending`: it is created in
  # `completed`, because its initiator was already allowed to make the deposit.
  aasm timestamps: true, whiny_transitions: false do
    state :pending, initial: true
    state :completed
    state :declined
    state :cancelled
    state :expired

    event :accept do
      transitions from: :pending, to: :completed
    end

    event :decline do
      transitions from: :pending, to: :declined
    end

    event :cancel do
      transitions from: :pending, to: :cancelled
    end

    event :expire do
      transitions from: :pending, to: :expired
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[aasm_state created_at updated_at expires_at completed_at declined_at cancelled_at expired_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def source
    source_inventory || source_fleet_inventory
  end

  def source=(inventory)
    self.source_inventory = inventory if inventory.is_a?(::Inventory)
    self.source_fleet_inventory = inventory if inventory.is_a?(::FleetInventory)
  end

  def destination
    destination_inventory || destination_fleet_inventory
  end

  def destination=(inventory)
    self.destination_inventory = inventory.is_a?(::Inventory) ? inventory : nil
    self.destination_fleet_inventory = inventory.is_a?(::FleetInventory) ? inventory : nil
  end

  # Who it is addressed to, when it is addressed to a party rather than to an
  # inventory.
  def recipient_party
    recipient || recipient_fleet
  end

  def recipient_party=(party)
    self.recipient = party.is_a?(::User) ? party : nil
    self.recipient_fleet = party.is_a?(::Fleet) ? party : nil
  end

  # Who is sending, which is the party holding the source rather than the person
  # who pressed the button. A fleet's stock is the fleet's, whoever moved it.
  def sender_party
    source_fleet_inventory&.fleet || source_inventory&.holder
  end

  # A transfer nobody has to answer: its initiator was allowed to deposit at the
  # destination themselves, so it was carried out on the spot.
  def immediate?
    recipient_party.blank?
  end

  def awaiting_answer?
    pending?
  end

  # The entries that left the source. These are the shipment: what a recipient
  # is being offered, and what is mirrored at the far end on acceptance.
  def dispatched_entries
    entries_on(source)&.where(entry_type: :withdrawal) || ::InventoryItem.none
  end

  # The entries this transfer wrote in one inventory, whichever of the two
  # ledgers that inventory keeps. `inventory_items` is the alias `InventoryStock`
  # installs on both classes.
  def entries_on(inventory)
    return if inventory.blank?

    inventory.inventory_items.where(inventory_transfer_id: id)
  end

  # Compared as records rather than as ids: an association assigned but not yet
  # saved has a nil foreign key, so checking ids would reject every valid build.
  private def exactly_one_source
    return if [source_inventory, source_fleet_inventory].compact.one?

    errors.add(:base, :invalid_source)
  end

  private def at_most_one_destination
    return if [destination_inventory, destination_fleet_inventory].compact.size <= 1

    errors.add(:base, :invalid_destination)
  end

  private def at_most_one_recipient
    return if [recipient, recipient_fleet].compact.size <= 1

    errors.add(:base, :invalid_recipient)
  end

  # A transfer with neither could never be delivered. Only checked while the row
  # is being written -- a party deleting their account nulls the column, and a
  # finished transfer must not become unsaveable because of it.
  private def has_a_target
    return if destination.present? || recipient_party.present?

    errors.add(:base, :no_target)
  end

  private def destination_is_not_the_source
    return if destination.blank?
    return unless destination == source

    errors.add(:base, :destination_is_source)
  end
end
