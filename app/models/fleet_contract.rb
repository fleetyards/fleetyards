# frozen_string_literal: true

# A job a fleet posts for its members.
#
# Three kinds, and the difference between them is only where the goods come
# from: a `transport` contract moves them between two of the fleet's own
# inventories, `procurement` buys them from outside, and `crafting` makes them
# to a required quality. All three end the same way -- the goods are deposited
# into the destination inventory by a transfer that names this contract.
#
# Nothing here records how much has been delivered. That is a sum over the
# ledger entries those transfers wrote, and `Contracts::Progress` is the only
# thing that computes it. A column would be a stored aggregate the ledger
# deliberately never keeps, and it would let a contract be advanced by writing to it rather than
# by moving goods.
class FleetContract < ApplicationRecord
  include AASM
  include ActiveStorageVariants

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 24

  KINDS = {transport: 0, procurement: 1, crafting: 2}.freeze

  # How `reward` reads: the whole payment, a rate per SCU or unit delivered, or
  # nothing at all. No default -- a contract that pays nothing has to say so,
  # rather than arrive at it by leaving the field empty.
  REWARD_TYPES = {fixed: 0, per_unit: 1, none: 2}.freeze

  AVAILABLE_PRIVILEGES = [
    "fleet:contracts:read",
    "fleet:contracts:create",
    "fleet:contracts:update",
    "fleet:contracts:delete",
    "fleet:contracts:manage"
  ].freeze

  # Claiming and crewing ride on `read` rather than on a privilege of their own:
  # a contract only officers could take is not a job board.
  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:contracts:manage"],
    member: ["fleet:contracts:read"]
  }.freeze

  belongs_to :fleet, touch: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :source_fleet_inventory, class_name: "FleetInventory", optional: true
  belongs_to :destination_fleet_inventory, class_name: "FleetInventory", optional: true
  # The author's own inventory, for an author who cannot accept deliveries into
  # the fleet's. Deliveries into it are addressed to the author.
  belongs_to :destination_inventory, class_name: "Inventory", optional: true

  has_many :fleet_contract_items, -> { order(:position) }, dependent: :destroy
  accepts_nested_attributes_for :fleet_contract_items
  has_many :fleet_contract_assignments, dependent: :destroy
  has_many :contractors, through: :fleet_contract_assignments, source: :user

  # Nullified rather than destroyed: a transfer moved real goods, and deleting
  # the contract it was filed under must not delete the record of that.
  has_many :inventory_transfers, dependent: :nullify

  has_one :payout_ledger, as: :subject, dependent: :destroy

  enum :kind, KINDS
  # The column defaults to fixed only for a release that predates it.
  attribute :reward_type, default: nil
  enum :reward_type, REWARD_TYPES, prefix: :reward

  include SquadronRestrictable

  # A contract had no visibility of its own -- the privilege gate was the whole
  # of it -- so `members_only` is what it has always done, and `squadron_only`
  # is the new half.
  enum :visibility, {members_only: 0, squadron_only: 1}

  has_one_attached :cover_image
  validates :cover_image, no_vector_image: true

  # Optional: an untitled contract describes itself from its goods. Still unique
  # when given, so two jobs in one fleet cannot share a name.
  validates :title, uniqueness: {case_sensitive: false, scope: :fleet_id}, allow_blank: true
  validate :slug_not_taken, if: -> { title.present? && will_save_change_to_title? }
  validates :reward_type, presence: true
  validates :reward, numericality: {greater_than: 0}, unless: :reward_none?
  validates :crew_limit, numericality: {greater_than: 0}, allow_nil: true
  validate :exactly_one_destination, if: :destination_being_set?
  validates :source_fleet_inventory, presence: true, if: :transport?
  validates :source_fleet_inventory, absence: true, unless: :transport?
  validate :inventories_belong_to_the_fleet
  validate :destination_is_not_the_source
  validate :goods_asked_for_once
  validate :hangar_destination_is_the_authors
  validate :destination_selectable_by_editor, if: :destination_changing?
  validate :personal_contracts_allowed, on: :create, if: :personal?
  validate :source_selectable_by_editor, if: :personal_source_changing?

  before_validation :clear_reward, if: :reward_none?
  before_save :update_slug

  scope :active, -> { where(aasm_state: %w[open in_progress]) }
  scope :personal, -> { where.not(destination_inventory_id: nil) }
  scope :fleet_owned, -> { where(destination_inventory_id: nil) }
  scope :closed, -> { where(aasm_state: %w[fulfilled settled cancelled expired]) }

  # The contracts somebody is actually working, which is the accepted seats --
  # a withdrawn or refused request is not work they are on. `distinct` because
  # a lead who is also crew would otherwise arrive twice.
  scope :worked_by, ->(user) {
    joins(:fleet_contract_assignments)
      .where(fleet_contract_assignments: {user_id: user, aasm_state: "accepted"})
      .distinct
  }

  # An expired contract is still work in hand while a delivery filed before the
  # deadline waits for an answer, because accepting it still counts.
  scope :without_settled_expiry, -> {
    where.not(aasm_state: "expired")
      .or(where(id: InventoryTransfer.pending.where.not(fleet_contract_id: nil).select(:fleet_contract_id)))
  }

  # Everything a delivery can still land on: on the board, being worked, or
  # expired while a delivery filed before the deadline waits for an answer.
  # Only a transfer that can end up in the destination keeps an expired one
  # here -- a transport's pickup waiting on its crew does not.
  scope :still_receiving, -> {
    pending_delivery = InventoryTransfer.pending
      .where("inventory_transfers.fleet_contract_id = fleet_contracts.id")
      .where(<<~SQL.squish)
        inventory_transfers.destination_inventory_id = fleet_contracts.destination_inventory_id
        OR inventory_transfers.destination_fleet_inventory_id = fleet_contracts.destination_fleet_inventory_id
        OR (fleet_contracts.destination_inventory_id IS NOT NULL
          AND inventory_transfers.recipient_id = fleet_contracts.created_by_id)
        OR (fleet_contracts.destination_fleet_inventory_id IS NOT NULL
          AND inventory_transfers.recipient_fleet_id = fleet_contracts.fleet_id)
      SQL

    where(aasm_state: %w[open in_progress])
      .or(where(aasm_state: "expired").where(pending_delivery.arel.exists))
  }

  # The contracts still receiving whose progress reads deposits out of this
  # inventory: the ones delivering into it, and the ones an addressed delivery
  # was accepted into it for -- the same two cases `Contracts::Progress`
  # counts. Deleting it would take those deposits, and the progress, with it.
  scope :counting_deliveries_in, ->(inventory) {
    fleet = inventory.is_a?(::FleetInventory)
    column = fleet ? :destination_fleet_inventory_id : :destination_inventory_id
    addressed = if fleet
      "inventory_transfers.recipient_fleet_id = fleet_contracts.fleet_id"
    else
      "inventory_transfers.recipient_id = fleet_contracts.created_by_id"
    end
    accepted_here = InventoryTransfer.completed
      .where("inventory_transfers.fleet_contract_id = fleet_contracts.id")
      .where(column => inventory.id)
      .where(addressed)

    still_receiving.where(column => inventory.id)
      .or(still_receiving.where.not(column => nil).where(accepted_here.arel.exists))
  }

  # `whiny_transitions: false` matches the rest of the app's state machines.
  # The two stamps aasm cannot write are written by hand: its timestamp feature
  # derives the column from the *state* name, so `open` would want `open_at` and
  # `in_progress` an `in_progress_at`, and neither says what the column means.
  # `fulfilled`, `cancelled` and `expired` line up, so aasm fills those.
  aasm timestamps: true, whiny_transitions: false do
    state :draft, initial: true
    state :open
    state :in_progress
    state :fulfilled
    state :settled
    state :cancelled
    state :expired

    event :publish do
      transitions from: :draft, to: :open, guard: :ready_to_publish?
      after { self.published_at ||= Time.current }
    end

    event :claim do
      transitions from: :open, to: :in_progress
      after { self.claimed_at = Time.current }
    end

    # The lead walking away. Deliveries already in the ledger stay there and
    # still count -- the goods are in the fleet's inventory either way.
    event :release do
      transitions from: :in_progress, to: :open
      after { self.claimed_at = nil }
    end

    # From `expired` too: a delivery still in flight at the deadline can be
    # accepted afterwards, and the goods it lands count the same. `expired_at`
    # stays, as the record that the deadline was missed.
    event :fulfil do
      transitions from: [:in_progress, :expired], to: :fulfilled
    end

    # Carried from the payout ledger rather than called on its own: settling
    # is what freezes who gets paid what, and the contract only reports it.
    event :settle do
      transitions from: :fulfilled, to: :settled
    end

    # Runs after aasm's own timestamp hook and before the save, so it can undo
    # that hook restamping `fulfilled_at`: the goods arrived when they arrived,
    # not when somebody reopened the payout.
    event :reopen do
      transitions from: :settled, to: :fulfilled, after: :restore_fulfilment
    end

    event :cancel do
      transitions from: [:draft, :open, :in_progress], to: :cancelled
    end

    event :expire do
      transitions from: [:open, :in_progress], to: :expired
    end
  end

  DEFAULT_SORTING_PARAMS = ["created_at desc"]
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "state asc", "state desc",
    "deadline asc", "deadline desc",
    "reward asc", "reward desc",
    "createdAt asc", "createdAt desc"
  ].freeze

  # `state` is the word everything outside the model uses. Ransack checks the
  # allowlist for the alias while parsing the key and again for the column it
  # lands on, so both have to be listed.
  ransack_alias :state, :aasm_state

  # Sorted by what a contract pays, not by the number typed in: a rate per SCU
  # sits beside fixed totals only once it is multiplied out over the goods. The
  # same figure `max_reward` derives, named over the column so `reward asc`
  # keeps its meaning.
  ransacker :reward, type: :decimal do
    Arel.sql(<<~SQL.squish)
      (CASE WHEN fleet_contracts.reward_type = #{REWARD_TYPES[:per_unit]}
        THEN fleet_contracts.reward * COALESCE((SELECT SUM(fleet_contract_items.quantity)
          FROM fleet_contract_items WHERE fleet_contract_items.fleet_contract_id = fleet_contracts.id), 0)
        ELSE fleet_contracts.reward END)
    SQL
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title slug state aasm_state kind reward reward_type deadline created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet destination_fleet_inventory destination_inventory source_fleet_inventory]
  end

  # Whoever is setting the destination on this save. Picking one is checked
  # against *their* rights, which the model cannot know by itself; left unset,
  # as it is for every save that does not come from the contract form, the
  # destination is not re-checked.
  attr_accessor :destination_chosen_by

  def destination
    destination_inventory || destination_fleet_inventory
  end

  # Who a delivery the contractor cannot put away themselves is addressed to:
  # the fleet for one of its inventories, the author for their own.
  def destination_party
    ::InventoryTransfer.party_of(destination)
  end

  def hangar_destination?
    destination_inventory.present?
  end

  # Whether this member could post one at all: the fleet allows them, and the
  # member's own inventories can take a delivery -- the transfer gate refuses
  # every one otherwise, so the contract could never be worked.
  def self.personal_open_to?(fleet, user)
    return false if fleet.blank? || user.blank?
    return false unless fleet.personal_contracts_enabled?

    ::Inventories::TransferGate.new(sender: user, recipient: user).recipient_feature_enabled?
  end

  # Delivering into the author's own inventory rather than the fleet's: the
  # author is the one paying for it.
  def personal?
    destination_inventory_id.present? || destination_inventory.present?
  end

  # Only a transport contract has somewhere to collect from, so only it has a
  # pickup leg to track.
  def requires_pickup?
    transport?
  end

  def lead_assignment
    fleet_contract_assignments.accepted.lead.first
  end

  def lead
    lead_assignment&.user
  end

  def crew_assignments
    fleet_contract_assignments.accepted.crew
  end

  # Everyone whose deliveries count and who shares in the reward.
  def contractor_assignments
    fleet_contract_assignments.accepted
  end

  def contractor?(user)
    return false if user.blank?

    contractor_assignments.exists?(user_id: user.id)
  end

  def lead?(user)
    return false if user.blank?

    lead_assignment&.user_id == user.id
  end

  # What the contract is called. The stored title is an override; without one it
  # describes itself from the goods it asks for -- "Buy 800 SCU Titanium at 500+
  # quality" -- which is the thing the author would have typed anyway.
  #
  # Derived here rather than in the client because notifications and mails need
  # the same sentence, and `I18n.t` already resolves to the right locale in both
  # places. The API publishes this as `title`.
  def display_title
    return title if title.present?

    goods = fleet_contract_items.ordered.to_a

    return I18n.t("fleet_contracts.generated_title.empty.#{kind}") if goods.empty?

    I18n.t("fleet_contracts.generated_title.#{kind}", goods: goods_summary(goods))
  end

  # The first line spelled out, with the rest counted. Listing four sets of goods
  # in a heading is unreadable, and the detail page shows them all anyway.
  private def goods_summary(goods)
    first = describe_goods(goods.first)

    return first if goods.size == 1

    I18n.t("fleet_contracts.generated_title.more", goods: first, count: goods.size - 1)
  end

  private def describe_goods(item)
    described = I18n.t("fleet_contracts.generated_title.goods",
      quantity: ActiveSupport::NumberHelper.number_to_delimited(item.quantity.to_i),
      unit: I18n.t("fleet_contracts.units.#{item.unit}"),
      name: item.name)

    return described if item.quality.blank?

    I18n.t("fleet_contracts.generated_title.quality.#{item.quality_match}",
      goods: described, quality: item.quality)
  end

  def progress
    @progress ||= ::Contracts::Progress.new(self)
  end

  # The most this contract can pay: a per-unit rate earns at most what the
  # lines ask for, because over-delivering a line does not count.
  def max_reward
    case reward_type
    when "fixed" then reward
    when "per_unit" then reward * fleet_contract_items.sum(0.to_d, &:quantity)
    else 0.to_d
    end
  end

  # What the delivered goods earned, for the contractors who delivered them --
  # `user_ids` leaves out an author paying themselves. A fixed reward is owed
  # whole; a rate is owed on what was counted, never beyond what was asked.
  def earned_reward(user_ids)
    case reward_type
    when "fixed" then reward
    when "per_unit" then (reward * progress.counted_quantities.slice(*user_ids).values.sum(0.to_d)).round(2)
    else 0.to_d
    end
  end

  private def clear_reward
    self.reward = 0
  end

  private def restore_fulfilment
    self.fulfilled_at = fulfilled_at_was
    self.settled_at = nil
  end

  def open_for_work?
    in_progress?
  end

  def accepting_crew?
    return false unless in_progress?
    return true if crew_limit.blank?

    crew_assignments.count < crew_limit
  end

  # Publishing a contract with nothing to deliver would create a job that is
  # fulfilled the moment it is claimed.
  def ready_to_publish?
    destination.present? && fleet_contract_items.any?
  end

  # The two inventories this contract's transfers are allowed to touch. Anything
  # else is a transfer that happens to have been made by a contractor, and
  # counts for nothing.
  def tracked_inventory_ids
    [source_fleet_inventory_id, destination_fleet_inventory_id, destination_inventory_id].compact
  end

  # Claiming is a race: two members pressing the button at once both read an
  # open contract. The row lock orders them, and the partial unique index on the
  # accepted lead is the backstop if one ever gets past it.
  #
  # `raise ActiveRecord::Rollback` rather than returning out of the block --
  # since Rails 7 a `return` inside a transaction *commits* it, which would
  # leave a lead row on a contract that never moved.
  def claim_by(user)
    claimed = false

    transaction do
      lock!

      if open?
        assignment = fleet_contract_assignments.find_or_initialize_by(user: user)
        assignment.role = :lead
        assignment.approved_by = user
        assignment.aasm_state = "accepted"
        assignment.accepted_at = Time.current

        claimed = assignment.save && claim!
      else
        errors.add(:base, :not_open)
      end

      raise ActiveRecord::Rollback unless claimed
    end

    claimed
  rescue ActiveRecord::RecordNotUnique
    errors.add(:base, :already_claimed)
    false
  end

  # The lead walking away, or a manager taking it off them. The whole crew goes
  # with them -- they signed up to work under that lead -- but their deliveries
  # stay in the ledger and still count. Who did it is paper_trail's to record,
  # so this takes no actor.
  def release_to_board!
    released = false

    transaction do
      lock!

      if in_progress?
        fleet_contract_assignments.accepted.find_each { |assignment| assignment.withdraw! }
        fleet_contract_assignments.requested.find_each { |assignment| assignment.decline! }
        released = release!
      else
        errors.add(:base, :not_in_progress)
      end

      raise ActiveRecord::Rollback unless released
    end

    released
  end

  private def inventories_belong_to_the_fleet
    [source_fleet_inventory, destination_fleet_inventory].compact.each do |inventory|
      next if inventory.fleet_id == fleet_id

      errors.add(:base, :inventory_not_in_fleet)
    end
  end

  # A line checks itself against the lines already saved, which misses the
  # ones written in the same request -- a new contract and its goods are one
  # save, and two identical lines there would only meet the unique index.
  #
  # Read from the lines in memory only: loading the association here would
  # cache it, and lines created through it afterwards would go missing from
  # that cache.
  private def goods_asked_for_once
    lines = fleet_contract_items.target.reject(&:marked_for_destruction?)
    return if lines.map(&:request_identity).uniq.size == lines.size

    errors.add(:fleet_contract_items, :taken,
      message: I18n.t("activerecord.errors.messages.contract_item_already_asked_for"))
  end

  # Two titles the check above tells apart can still read the same slug --
  # "Get Iron " and "Get Iron!" are both `get-iron` -- and the unique index on
  # (fleet_id, slug) would refuse the second.
  private def slug_not_taken
    return if errors.added?(:title, :taken)
    return unless self.class.where(fleet_id:, slug: self.class.slug_for(title)).where.not(id:).exists?

    errors.add(:title, :taken)
  end

  private def destination_is_not_the_source
    return if source_fleet_inventory_id.blank?
    return unless source_fleet_inventory_id == destination_fleet_inventory_id

    errors.add(:destination_fleet_inventory, :same_as_source)
  end

  # Compared as records rather than ids, so an association assigned but not
  # yet saved still counts.
  private def exactly_one_destination
    case [destination_fleet_inventory, destination_inventory].compact.size
    when 0 then errors.add(:destination_fleet_inventory, :blank)
    when 2 then errors.add(:destination_inventory, :only_one_destination)
    end
  end

  private def hangar_destination_is_the_authors
    return if destination_inventory.blank?
    return if created_by.present? && destination_inventory.holder == created_by

    errors.add(:destination_inventory, :not_the_authors)
  end

  # Both columns are ON DELETE SET NULL, so deleting the inventory clears the
  # destination in the database and the loaded row simply arrives without one.
  # That is not a save choosing no destination, and refusing it would leave the
  # contract unable to be cancelled or expired -- `whiny_transitions: false`
  # turns the failed save into a silent `false`.
  private def destination_being_set?
    new_record? ||
      will_save_change_to_destination_fleet_inventory_id? ||
      will_save_change_to_destination_inventory_id?
  end

  private def destination_changing?
    destination_chosen_by.present? &&
      (will_save_change_to_destination_fleet_inventory_id? || will_save_change_to_destination_inventory_id?)
  end

  # Collecting from a fleet inventory into somebody's own is moving the
  # fleet's stock out of it, which only whoever writes the fleet's contracts
  # may ask for -- reading the board is enough for a personal contract, not
  # for that.
  private def personal_source_changing?
    destination_chosen_by.present? && personal? && source_fleet_inventory_id.present? &&
      (new_record? || will_save_change_to_source_fleet_inventory_id? ||
        will_save_change_to_destination_inventory_id?)
  end

  private def source_selectable_by_editor
    return if ::FleetContractPolicy.new(fleet, user: destination_chosen_by).write_fleet_contracts?

    errors.add(:source_fleet_inventory, :not_selectable)
  end

  private def personal_contracts_allowed
    return if fleet.blank? || fleet.personal_contracts_enabled?

    errors.add(:destination_inventory, :personal_contracts_disabled)
  end

  private def destination_selectable_by_editor
    return if destination.blank?

    options = ::Contracts::DestinationOptions.new(fleet:, editor: destination_chosen_by, author: created_by)
    return if options.allows?(destination)

    attribute = destination_inventory.present? ? :destination_inventory : :destination_fleet_inventory
    errors.add(attribute, :not_selectable)
  end

  # Only from a real title, and only while there is one. A derived title moves
  # every time the goods do, and a slug following it would break every link
  # already shared -- so an untitled contract takes its kind and a random
  # suffix, once.
  #
  # `Mission`'s shape rather than `FleetEvent`'s, which prefixes with the first
  # segment of the id: that is nil in a `before_save` on create, because the
  # database generates the uuid, so the prefix would only appear on the *second*
  # save and move the URL under anyone holding the first one.
  private def update_slug
    return if slug.present? && !will_save_change_to_title?

    self.slug = title.present? ? generate_slug(title) : "#{kind}-#{SecureRandom.hex(4)}"
  end
end
