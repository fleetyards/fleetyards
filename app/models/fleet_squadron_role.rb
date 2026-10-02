# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadron_roles
#
#  id           :uuid             not null, primary key
#  default_rank :boolean          default(FALSE), not null
#  key          :string           not null
#  name         :string           not null
#  position     :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  fleet_id     :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_roles_on_fleet_id_and_key       (fleet_id,key) UNIQUE
#  index_fleet_squadron_roles_on_one_default_per_fleet  (fleet_id) UNIQUE WHERE default_rank
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
class FleetSquadronRole < ApplicationRecord
  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  belongs_to :fleet, touch: true

  has_many :fleet_squadron_memberships, dependent: :restrict_with_exception

  # The rows are a fleet's names for four fixed slots. The key, not the name,
  # carries the order, the one-holder limit and what the rank may do, so a
  # fleet that renames "Squadron Leader" to "Wing Commander" changes nothing
  # else.
  KEYS = %w[leader co_leader officer member].freeze

  DEFAULT_NAMES = {
    "leader" => "Squadron Leader",
    "co_leader" => "Co-Leader",
    "officer" => "Squadron Officer",
    "member" => "Member"
  }.freeze

  SINGLE_HOLDER_KEYS = %w[leader co_leader].freeze

  MEMBERS_MANAGER_KEYS = %w[leader co_leader officer].freeze

  RANKS_MANAGER_KEYS = %w[leader co_leader].freeze

  # The leadership a squadron cannot do without. A new member never starts
  # there -- each holds one person -- so neither can be the default.
  PERMANENT_KEYS = %w[leader co_leader].freeze

  SEEDED_DEFAULT_KEY = "member"

  validates :key, inclusion: {in: KEYS}, uniqueness: {scope: :fleet_id}

  validates :name, presence: true, length: {maximum: 255}

  validate :permanent_rank_is_never_the_default
  validate :default_is_handed_over_not_dropped

  attr_readonly :key, :position

  attr_accessor :handing_over_default

  # Under the fleet's row lock, like every write that has to see the fleet's
  # whole set of ranks: two first requests for an unseeded fleet would
  # otherwise both miss a rank and race to insert it.
  def self.setup_defaults!(fleet)
    with_fleet_lock(fleet) do
      KEYS.each_with_index do |key, position|
        fleet.fleet_squadron_roles.find_or_create_by!(key:) do |role|
          role.name = DEFAULT_NAMES.fetch(key)
          role.position = position
          role.default_rank = key == SEEDED_DEFAULT_KEY
        end
      end
    end
  end

  def self.with_fleet_lock(fleet, &)
    transaction do
      Fleet.where(id: fleet.id).lock.take
      yield
    end
  end

  # The rank a new squadron member starts on. A fleet created before the
  # ranks existed -- or by a release still running while they were migrated
  # in -- has none, and seeding on the miss keeps such a fleet from refusing
  # every new squadron member.
  def self.default_for(fleet)
    fleet.fleet_squadron_roles.find_by(default_rank: true) || begin
      setup_defaults!(fleet)
      fleet.fleet_squadron_roles.find_by!(default_rank: true)
    end
  end

  # There is always exactly one default, so it moves rather than being set and
  # cleared: the old one gives it up in the same transaction, before the
  # partial unique index sees two. The fleet lock serialises two moves, and
  # both rows are read again under it -- the default may have moved while
  # this one waited.
  def make_default!
    self.class.with_fleet_lock(fleet) do
      reload
      next if default_rank?

      fleet.fleet_squadron_roles.where(default_rank: true).where.not(id:).find_each do |previous|
        previous.handing_over_default = true
        previous.update!(default_rank: false)
      end

      update!(default_rank: true)
    end
  end

  def permanent?
    PERMANENT_KEYS.include?(key)
  end

  def single_holder?
    SINGLE_HOLDER_KEYS.include?(key)
  end

  def manages_members?
    MEMBERS_MANAGER_KEYS.include?(key)
  end

  def manages_ranks?
    RANKS_MANAGER_KEYS.include?(key)
  end

  def leader?
    key == "leader"
  end

  private def permanent_rank_is_never_the_default
    return unless default_rank? && permanent?

    errors.add(:default_rank, :permanent)
  end

  private def default_is_handed_over_not_dropped
    return unless persisted? && will_save_change_to_default_rank?(from: true, to: false)
    return if handing_over_default

    errors.add(:default_rank, :required)
  end
end
