# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadron_roles
#
#  id         :uuid             not null, primary key
#  key        :string           not null
#  name       :string           not null
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  fleet_id   :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_roles_on_fleet_id_and_key  (fleet_id,key) UNIQUE
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

  DEFAULT_KEY = "member"

  validates :key, inclusion: {in: KEYS}, uniqueness: {scope: :fleet_id}

  validates :name, presence: true, length: {maximum: 255}

  attr_readonly :key, :position

  def self.setup_defaults!(fleet)
    KEYS.each_with_index do |key, position|
      fleet.fleet_squadron_roles.find_or_create_by!(key:) do |role|
        role.name = DEFAULT_NAMES.fetch(key)
        role.position = position
      end
    end
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
end
