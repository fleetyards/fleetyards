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
# thing that computes it. A column would be the stored aggregate #4855 D2
# refused, and it would let a contract be advanced by writing to it rather than
# by moving goods.
# == Schema Information
#
# Table name: fleet_contracts
#
#  id                             :uuid             not null, primary key
#  aasm_state                     :string           default("draft"), not null
#  cancelled_at                   :datetime
#  claimed_at                     :datetime
#  crew_limit                     :integer
#  deadline                       :datetime
#  description                    :text
#  expired_at                     :datetime
#  fulfilled_at                   :datetime
#  kind                           :integer          default(0), not null
#  published_at                   :datetime
#  reimburse_expenses             :boolean          default(TRUE), not null
#  reward                         :decimal(15, 2)   default(0.0), not null
#  slug                           :string           not null
#  title                          :string           not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  created_by_id                  :uuid
#  destination_fleet_inventory_id :uuid
#  fleet_id                       :uuid             not null
#  source_fleet_inventory_id      :uuid
#
# Indexes
#
#  index_fleet_contracts_on_created_by_id                   (created_by_id)
#  index_fleet_contracts_on_destination_fleet_inventory_id  (destination_fleet_inventory_id)
#  index_fleet_contracts_on_fleet_id                        (fleet_id)
#  index_fleet_contracts_on_fleet_id_and_aasm_state         (fleet_id,aasm_state)
#  index_fleet_contracts_on_fleet_id_and_kind               (fleet_id,kind)
#  index_fleet_contracts_on_fleet_id_and_slug               (fleet_id,slug) UNIQUE
#  index_fleet_contracts_on_source_fleet_inventory_id       (source_fleet_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (destination_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (source_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#
class FleetContract < ApplicationRecord
  include AASM

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

  has_many :fleet_contract_items, -> { order(:position) }, dependent: :destroy
  has_many :fleet_contract_assignments, dependent: :destroy
  has_many :contractors, through: :fleet_contract_assignments, source: :user

  # Nullified rather than destroyed: a transfer moved real goods, and deleting
  # the contract it was filed under must not delete the record of that.
  has_many :inventory_transfers, dependent: :nullify

  enum :kind, KINDS

  validates :title, presence: true, uniqueness: {case_sensitive: false, scope: :fleet_id}
  validates :reward, numericality: {greater_than_or_equal_to: 0}
  validates :crew_limit, numericality: {greater_than: 0}, allow_nil: true
  validates :destination_fleet_inventory, presence: true
  validates :source_fleet_inventory, presence: true, if: :transport?
  validates :source_fleet_inventory, absence: true, unless: :transport?
  validate :inventories_belong_to_the_fleet
  validate :destination_is_not_the_source

  before_save :update_slug

  scope :active, -> { where(aasm_state: %w[open in_progress]) }
  scope :closed, -> { where(aasm_state: %w[fulfilled cancelled expired]) }

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

    event :fulfil do
      transitions from: :in_progress, to: :fulfilled
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
    %w[fleet destination_fleet_inventory source_fleet_inventory]
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
    destination_fleet_inventory.present? && fleet_contract_items.any?
  end

  # The two inventories this contract's transfers are allowed to touch. Anything
  # else is a transfer that happens to have been made by a contractor, and
  # counts for nothing.
  def tracked_inventory_ids
    [source_fleet_inventory_id, destination_fleet_inventory_id].compact
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

  # `Mission`'s shape, not `FleetEvent`'s. FleetEvent prefixes the slug with the
  # first segment of the id, which is nil in a `before_save` on create -- the
  # database generates the uuid -- so the prefix only appears on the *second*
  # save and the URL moves under anyone holding the first one. Uniqueness here
  # comes from the case-insensitive title validation, with the unique index on
  # [fleet_id, slug] as the backstop.
  private def update_slug
    self.slug = generate_slug(title)
  end
end
