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
# == Schema Information
#
# Table name: fleet_contracts
#
#  id                             :uuid             not null, primary key
#  aasm_state                     :string           default("draft"), not null
#  cancelled_at                   :datetime
#  claimed_at                     :datetime
#  cover_image_preset             :string
#  crew_limit                     :integer
#  deadline                       :datetime
#  description                    :text
#  expired_at                     :datetime
#  fulfilled_at                   :datetime
#  kind                           :integer          default("transport"), not null
#  published_at                   :datetime
#  reimburse_expenses             :boolean          default(TRUE), not null
#  reward                         :decimal(15, 2)   default(0.0), not null
#  slug                           :string           not null
#  title                          :string
#  visibility                     :integer          default("members_only"), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  created_by_id                  :uuid
#  destination_fleet_inventory_id :uuid
#  destination_inventory_id       :uuid
#  fleet_id                       :uuid             not null
#  source_fleet_inventory_id      :uuid
#
# Indexes
#
#  index_fleet_contracts_on_created_by_id                   (created_by_id)
#  index_fleet_contracts_on_destination_fleet_inventory_id  (destination_fleet_inventory_id)
#  index_fleet_contracts_on_destination_inventory_id        (destination_inventory_id)
#  index_fleet_contracts_on_fleet_id_and_aasm_state         (fleet_id,aasm_state)
#  index_fleet_contracts_on_fleet_id_and_kind               (fleet_id,kind)
#  index_fleet_contracts_on_fleet_id_and_slug               (fleet_id,slug) UNIQUE
#  index_fleet_contracts_on_source_fleet_inventory_id       (source_fleet_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (destination_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (destination_inventory_id => inventories.id) ON DELETE => nullify
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (source_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#
class FleetContract < ApplicationRecord
  include AASM
  include ActiveStorageVariants

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 30

  KINDS = {transport: 0, procurement: 1, crafting: 2}.freeze

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

  enum :kind, KINDS

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
  validates :reward, numericality: {greater_than_or_equal_to: 0}
  validates :crew_limit, numericality: {greater_than: 0}, allow_nil: true
  validate :exactly_one_destination, if: :destination_being_set?
  validates :source_fleet_inventory, presence: true, if: :transport?
  validates :source_fleet_inventory, absence: true, unless: :transport?
  validate :inventories_belong_to_the_fleet
  validate :destination_is_not_the_source
  validate :hangar_destination_is_the_authors
  validate :destination_selectable_by_editor, if: :destination_changing?

  before_save :update_slug

  scope :active, -> { where(aasm_state: %w[open in_progress]) }
  scope :closed, -> { where(aasm_state: %w[fulfilled cancelled expired]) }

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

  def self.ransackable_attributes(_auth_object = nil)
    %w[title slug state aasm_state kind reward deadline created_at updated_at]
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
