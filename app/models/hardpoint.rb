# == Schema Information
#
# Table name: hardpoints
#
#  id             :uuid             not null, primary key
#  category       :integer
#  group          :integer
#  group_key      :string
#  hardpoint_type :integer
#  max_size       :integer
#  min_size       :integer
#  parent_type    :string           not null
#  sc_name        :string
#  source         :integer
#  types          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  component_id   :uuid
#  parent_id      :uuid             not null
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

  belongs_to :parent, polymorphic: true
  belongs_to :component, optional: true
  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true

  enum source: {ship_matrix: 0, game_files: 1}
  enum group: {
    avionic: 0, system: 1, propulsion: 2, thruster: 3, weapon: 4, defense: 5, auxiliary: 6, seat: 7, relay: 8,
    other: 9
  }, _suffix: true
  enum category: {
    radar: 1, computers: 2, scanners: 3,
    powerplant: 10, cooler: 11, shieldgenerator: 12, module: 13, salvagefillerstation: 14,
    fueltanks: 20, fuel_intakes: 21, quantumdrive: 22, jumpdrive: 23,
    main_thrusters: 30, maneuvering_thrusters: 31,
    weapons: 40, weapon_mounts: 41, turret: 42, missile_racks: 43, bombcompartments: 44,
    quantumenforcementdevice: 45, emp: 46, salvagemunching: 47,
    armor: 50, countermeasures: 51,
    selfdestruct: 60, lifesupport: 61, batteries: 62, utility: 63,
    seat: 70,
    relay: 80,
    paints: 90, doors: 91, cargogrid: 92, inventory: 93, controller: 94,
    unknown: 999
  }, _suffix: true

  before_validation :set_group, :set_category, :set_group_key

  def set_group
    self.group = case component&.category
    when "thrusters"
      :thruster
    when "seat"
      :seat
    when "selfdestruct", "lifesupport", "armor", "countermeasures", "batteries", "relay", "utility"
      :auxiliary
    when "radar", "computers", "scanners"
      :avionic
    when "powerplant", "cooler", "shieldgenerator", "module", "salvagefillerstation"
      :system
    when "turret", "weapon_mounts", "weapons", "missile_racks", "bombcompartments",
      "quantumenforcementdevice", "salvagemunching"
      :weapon
    when "fueltanks", "fuel_intakes", "quantumdrive"
      :propulsion
    else
      :other
    end

    if sc_name.start_with?("hardpoint_engineering")
      self.group = :seat
    end

    if sc_name.start_with?("hardpoint_relay_")
      self.group = :relay
    end
  end

  def set_category
    self.category = case component&.component_type
    when "EMP"
      :emp
    when "MainThruster"
      :main_thrusters
    when "ManneuverThruster"
      :maneuvering_thrusters
    else
      component&.category || :unknown
    end
  end

  def set_group_key
    self.group_key = group_keys.flatten.uniq.join("-").presence || group_keys(with_component: true).flatten.uniq.join("-")
  end

  def group_keys(with_component: false)
    [
      (component_id if with_component),
      (hardpoints.count if hardpoints.present? && hardpoints.count > 1),
      (hardpoints.map { |item| item.group_keys(with_component: true) } if hardpoints.present?)
    ].compact
  end
end
