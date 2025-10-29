# == Schema Information
#
# Table name: hardpoints
#
#  id           :uuid             not null, primary key
#  category     :integer
#  details      :string
#  group        :integer
#  group_key    :string
#  matrix_key   :string
#  max_size     :integer
#  min_size     :integer
#  parent_type  :string           not null
#  sc_name      :string
#  source       :integer
#  types        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  component_id :uuid
#  parent_id    :uuid             not null
#
# Indexes
#
#  index_hardpoints_on_component_id  (component_id)
#  index_hardpoints_on_parent        (parent_type,parent_id)
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

  belongs_to :parent, polymorphic: true, touch: true
  belongs_to :component, optional: true
  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true

  enum :source,
    {ship_matrix: 0, game_files: 1}

  enum :group,
    {
      avionic: 0, system: 1, propulsion: 2, thruster: 3, weapon: 4, defense: 5, auxiliary: 6,
      seat: 7, relay: 8,
      other: 9,
      unknown: 99
    },
    suffix: true

  enum :category,
    {
      radar: 1, computers: 2, scanners: 3,
      powerplant: 10, cooler: 11, shieldgenerator: 12, module: 13, salvagefillerstation: 14,
      fueltanks: 20, fuel_intakes: 21, quantumdrive: 22, jumpdrive: 23,
      main_thrusters: 30, retro_thrusters: 31, vtol_thrusters: 32, maneuvering_thrusters: 33,
      weapons: 40, weapon_mounts: 41, turret: 42, missile_racks: 43, bombcompartments: 44,
      quantumenforcementdevice: 45, emp: 46, salvagemunching: 47,
      armor: 50, countermeasures: 51,
      selfdestruct: 60, lifesupport: 61, batteries: 62, utility: 63,
      seat: 70,
      relay: 80,
      paints: 90, doors: 91, cargogrid: 92, inventory: 93, controller: 94,
      unknown: 999
    }, suffix: true

  before_validation :set_group, :set_category, :set_group_key

  def set_group
    return if group.present? && source == "ship_matrix"

    self.group = case component&.category
    when "thrusters"
      :thruster
    when "seat"
      :seat
    when "lifesupport", "armor", "countermeasures", "utility" # , "salvagemunching"
      :auxiliary
    when "radar", "computers", "scanners"
      :avionic
    when "powerplant", "cooler", "shieldgenerator"
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
      else
        component&.category || :unknown
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
