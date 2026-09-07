# == Schema Information
#
# Table name: hardpoints
#
#  id            :uuid             not null, primary key
#  category      :integer
#  details       :string
#  flags         :string
#  group         :integer
#  group_key     :string
#  matrix_key    :string
#  max_size      :integer
#  min_size      :integer
#  parent_type   :string           not null
#  port_tags     :string
#  required_tags :string
#  sc_name       :string
#  source        :integer
#  types         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  component_id  :uuid
#  parent_id     :uuid             not null
#
# Indexes
#
#  index_hardpoints_on_component_id        (component_id)
#  index_hardpoints_on_parent              (parent_type,parent_id)
#  index_hardpoints_on_parent_and_sc_name  (parent_type,parent_id,sc_name) UNIQUE WHERE (source = 1)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id)
#
class Hardpoint < ApplicationRecord
  GAME_FILE_CATEGORIES = %w[thrusters].freeze

  SHIP_MATRIX_CATEGORIES = %w[
    radar computers fuel_intakes
  ].freeze

  # The column is a string holding what an array serialised into it, which the
  # API has always declared -- and the generated client has always typed -- as
  # an array of strings. Read back as one, so the two agree. Every value ever
  # written is already valid JSON, so nothing needs rewriting.
  serialize :types, type: Array, coder: JSON

  # What the port carries, what it demands of whatever is put in it, and whether
  # it may be changed at all. Same storage as `types` above.
  serialize :port_tags, type: Array, coder: JSON
  serialize :required_tags, type: Array, coder: JSON
  serialize :flags, type: Array, coder: JSON

  belongs_to :parent, polymorphic: true, touch: true
  belongs_to :component, optional: true
  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true
  has_many :model_positions, dependent: :nullify

  # What each build of the game says about this slot. Written alongside the
  # columns for now, so the reads can move over in their own step -- and only
  # for `game_files` slots, since the matrix comes from no build.
  has_many :builds, class_name: "HardpointBuild", dependent: :destroy
  has_one :build, -> { current }, class_name: "HardpointBuild", inverse_of: :hardpoint

  enum :source,
    {ship_matrix: 0, game_files: 1}

  # The slots a build describes: the game-files ones carrying a row for it, plus
  # the whole matrix half, which comes from no build and whose facts live only on
  # the row.
  #
  # A no-op today for the game-files half, because the cleanup still destroys
  # every slot a load did not name -- so a slot exists if and only if it has a
  # row for the current build. It starts to mean something on the step that stops
  # destroying, and it has to be in place first: the other order shows every slot
  # ever retired in one response.
  scope :in_build, ->(source = ::ScData::Source.current) {
    where(source: :ship_matrix).or(where(id: HardpointBuild.current(source).select(:hardpoint_id)))
  }

  # Named constants rather than inline maps, because `HardpointBuild` declares
  # the same two: `group` and `category` are derived from the installed
  # component, so they move to the build row, and a build holding `40` has to
  # read as `weapons` there as well. Two copies of a 30-entry map is one copy
  # too many.
  GROUPS = {
    avionic: 0, system: 1, propulsion: 2, thruster: 3, weapon: 4, defense: 5, auxiliary: 6,
    seat: 7, relay: 8,
    other: 9,
    external_fuel_tank: 10,
    refuel_boom: 11,
    unknown: 99
  }.freeze

  CATEGORIES = {
    radar: 1, computers: 2, scanners: 3,
    powerplant: 10, cooler: 11, shieldgenerator: 12, module: 13, salvagefillerstation: 14,
    fueltanks: 20, fuel_intakes: 21, quantumdrive: 22, jumpdrive: 23, external_fuel_tanks: 24,
    refuel_boom: 25,
    main_thrusters: 30, retro_thrusters: 31, vtol_thrusters: 32, maneuvering_thrusters: 33,
    weapons: 40, weapon_mounts: 41, turret: 42, missile_racks: 43, bombcompartments: 44,
    quantumenforcementdevice: 45, emp: 46, salvagemunching: 47,
    armor: 50, countermeasures: 51,
    selfdestruct: 60, lifesupport: 61, batteries: 62, utility: 63,
    seat: 70,
    relay: 80,
    paints: 90, doors: 91, cargogrid: 92, inventory: 93, controller: 94,
    unknown: 999
  }.freeze

  enum :group, GROUPS, suffix: true

  enum :category, CATEGORIES, suffix: true

  # What the build in force says about this slot, or the row itself when no build
  # describes it -- which is the whole matrix half.
  #
  # An object to read from rather than reader overrides in the style of Component
  # and Equipment, and for a reason particular to this table: Hardpoint derives
  # `group`, `category` and `group_key` in a `before_validation`, and the enum
  # predicates those derivations use read the *attribute* rather than the reader.
  # Measured -- with `group` overridden to "weapon" over a stored `thruster`,
  # `thruster_group?` still answers true. An override would leave
  # `hardpoint.group` and `hardpoint.thruster_group?` disagreeing, and
  # `group_keys` reads both.
  #
  # Read through entirely rather than field by field: a build row's nil is an
  # answer, not a gap. An empty port in this build has to read as empty instead
  # of falling through to whatever the column last held.
  def facts
    build || self
  end

  # Not in the build we are on -- a port the loadout no longer has. Only ever
  # true for the game-files half; a matrix slot answers to no build.
  def retired?
    game_files? && build.blank?
  end

  def self.ransackable_attributes(auth_object = nil)
    ["category", "component_id", "created_at", "group", "id", "parent_id", "parent_type",
      "sc_name", "source", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["component", "hardpoints", "parent"]
  end

  before_validation :set_group, :set_category, :set_group_key

  def set_group
    return if group.present? && source == "ship_matrix"

    self.group = case component&.category
    when "thrusters"
      :thruster
    when "seat"
      :seat
    when "utility" # , "salvagemunching"
      :auxiliary
    when "armor", "countermeasures"
      :defense
    when "radar", "computers", "scanners"
      :avionic
    when "powerplant", "cooler", "shieldgenerator", "lifesupport"
      :system
    when "turret", "weapon_mounts", "weapons", "missile_racks", "bombcompartments",
      "quantumenforcementdevice"
      :weapon
    when "fueltanks", "fuel_intakes", "quantumdrive"
      :propulsion
    when "cargogrid", "module", "salvagefillerstation"
      :other
    when "relay", "batteries"
      :relay
    else
      :unknown
    end

    if component&.component_type == "ExternalFuelTank"
      self.group = :external_fuel_tank
    end

    if component&.category == "refuel_boom" || %w[DockingCollar ToolArm].include?(component&.component_type) && sc_name&.include?("refuel")
      self.group = :auxiliary
    end

    if sc_name&.start_with?("hardpoint_engineering", "hardpoint_engineeringscreen")
      self.group = :seat
    end

    if sc_name&.start_with?("hardpoint_mining_pod")
      self.group = :other
    end

    if sc_name&.start_with?("hardpoint_relay_")
      self.group = :relay
    end
  end

  def set_category
    return if category.present? && source == "ship_matrix"

    self.category = if thruster_group?
      case component&.type_data&.dig(:thruster_class)
      when "main", "aux"
        :main_thrusters
      when "retro"
        :retro_thrusters
      when "vtol"
        :vtol_thrusters
      else
        :maneuvering_thrusters
      end
    elsif sc_name&.start_with?("hardpoint_engineeringscreen")
      :seat
    elsif sc_name&.start_with?("hardpoint_mining_pod")
      :cargogrid
    else
      case component&.component_type
      when "EMP"
        :emp
      when "ExternalFuelTank"
        :external_fuel_tanks
      when "DockingCollar", "ToolArm"
        (component&.category == "refuel_boom") ? :utility : (component&.category || :unknown)
      else
        derived = component&.category || :unknown
        if derived.to_s == "module" && component&.component_type != "Module"
          :unknown
        else
          derived
        end
      end
    end
  end

  def set_group_key
    return if group_key.present? && source == "ship_matrix"

    self.group_key = group_keys.flatten.uniq.join("-").presence || group_keys(with_component: true).flatten.uniq.join("-")
  end

  def group_keys(with_component: false)
    if thruster_group?
      return [
        category,
        component&.type_data&.dig(:thruster_class),
        component&.type_data&.dig(:thrust_capacity)
      ].compact
    end

    [
      (component_id if with_component),
      (hardpoints.count if hardpoints.present? && hardpoints.count > 1),
      (hardpoints.map { |item| item.group_keys(with_component: true) } if hardpoints.present?)
    ].compact
  end
end
