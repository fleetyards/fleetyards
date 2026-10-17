# frozen_string_literal: true

# The slots of one fitting, found by slot path: hardpoint names from the hull
# down, `/`-joined, as the build in force describes them.
#
# Two trees answer a path and they say different things. A component's own
# ports (parented to the Component) carry what fits them -- types, size range,
# flags -- but no stock part. The ship's copy of that subtree (parented to the
# hull's Hardpoint) carries the parts the ship comes with, but no types. So a
# slot reads its rules from the port and its stock part from the ship's copy,
# and the ship's copy only applies while the part above it is still the stock
# one: swap a mount and its gun ports are the new mount's, empty.
#
# A component slot nothing is fitted to keeps its stock part, so what sits below
# it stays addressable. A module slot does not: a module is fitted by choice or
# not at all.
class LoadoutSlots
  Slot = Struct.new(:path, :port, :instance, :stock) do
    def name
      port.sc_name
    end

    def facts
      port.facts
    end

    def module_slot?
      facts.category == "module"
    end

    # The game marks the ports a player cannot swap -- most hull gimbals and
    # turrets on a fighter -- though what sits inside them can still change.
    def editable?
      Array(facts.flags).none? { |flag| flag.to_s.casecmp?("uneditable") }
    end

    def fits?(component)
      LoadoutSlots.fits?(port, component)
    end
  end

  # The catalogue components a port takes, best first by name. A port that names
  # neither types nor a category has nothing to match on and takes nothing.
  def self.options(port)
    facts = port.facts
    types = Array(facts.types).compact_blank
    return [] if types.empty? && (facts.category.blank? || facts.category == "unknown")

    scope = Component.current_version.named.order(:name)
    scope = types.any? ? scope.where(component_type: types) : scope.where(category: facts.category)
    scope.select { |component| fits?(port, component) }
  end

  # A port that names no types (68 life-support slots, among others) is matched
  # on the category the slot was filed under instead.
  def self.fits?(port, component)
    facts = port.facts
    types = Array(facts.types).compact_blank
    kind_matches = types.any? ? types.include?(component.component_type) : component.category == facts.category
    return false unless kind_matches

    size = Integer(component.size, exception: false)
    return false if size.nil?

    (facts.min_size.nil? || size >= facts.min_size) && (facts.max_size.nil? || size <= facts.max_size)
  end

  # The hull slots a player fits: the systems, the weapons and what holds them,
  # and the module slots, whose own slots open up once a module is fitted.
  # Doors, seats, thrusters and the rest are the shipwright's.
  HULL_CATEGORIES = %w[
    radar cooler lifesupport powerplant shieldgenerator quantumdrive controller
    weapons weapon_mounts turret missile_racks module
  ].freeze

  # Shield, missile and weapon controllers are ship internals; the flight blade
  # is the one controller a player swaps.
  FITTED_CONTROLLER_TYPES = Component::CATALOGUED_CONTROLLER_TYPES

  # `items` are `{slot_path:, item_type:, item_id:}` hashes, as a loadout's
  # `item_list` holds them.
  def initialize(model, items = [])
    @model = model
    @items = items.index_by { |item| item[:slot_path] }
    @below = {}
  end

  def [](path)
    parent_path, _, name = path.rpartition("/")
    return hull_slots[name] if parent_path.empty?

    parent = self[parent_path]
    parent && below(parent)[name]
  end

  def hull
    hull_slots.values
  end

  def fittable_hull
    hull.select do |slot|
      next false unless HULL_CATEGORIES.include?(slot.facts.category)
      next true unless slot.facts.category == "controller"

      FITTED_CONTROLLER_TYPES.include?(slot.stock&.component_type) ||
        Array(slot.facts.types).intersect?(FITTED_CONTROLLER_TYPES)
    end
  end

  def children(slot)
    below(slot).values
  end

  # Whether anything sits in the slot at `path` -- fitted there, or its stock
  # component left in place -- so a slot beneath it exists.
  def occupied?(path)
    return true if @items.key?(path)

    slot = self[path]
    slot.present? && !slot.module_slot? && slot.stock.present?
  end

  def fitted(path)
    item = @items[path]
    return if item.nil?

    records.dig(item[:item_type], item[:item_id])
  end

  private def hull_slots
    @hull_slots ||= @model.hardpoints.game_files.in_build.includes(Hardpoint::RENDERED)
      .to_h { |hardpoint| [hardpoint.sc_name, slot_at(nil, hardpoint, hardpoint, hardpoint.facts.component)] }
  end

  private def below(parent)
    @below[parent.path] ||= case (content = fitted(parent.path))
    when ModelModule
      ports(content).to_h { |port| [port.sc_name, slot_at(parent, port, port, port.facts.component)] }
    when Component
      (content.id == parent.stock&.id) ? below_stock(parent) : below_swapped(parent, content)
    else
      (@items.key?(parent.path) || parent.module_slot? || parent.stock.nil?) ? {} : below_stock(parent)
    end
  end

  private def below_swapped(parent, component)
    ports(component).to_h { |port| [port.sc_name, slot_at(parent, port, nil, port.facts.component)] }
  end

  private def below_stock(parent)
    ports = ports(parent.stock).index_by(&:sc_name)
    copies = parent.instance ? ports(parent.instance).select(&:game_files?).index_by(&:sc_name) : {}

    (ports.keys | copies.keys).to_h do |name|
      port = ports[name] || copies[name]
      instance = copies[name]
      [name, slot_at(parent, port, instance, (instance || port).facts.component)]
    end
  end

  private def slot_at(parent, port, instance, stock)
    path = parent ? "#{parent.path}/#{port.sc_name}" : port.sc_name
    Slot.new(path:, port:, instance:, stock:)
  end

  private def ports(owner)
    owner.hardpoints.in_build.includes(Hardpoint::RENDERED).to_a
  end

  private def records
    @records ||= @items.values.group_by { |item| item[:item_type] }.to_h do |type, items|
      klass = VehicleLoadoutItem::ITEM_TYPES.include?(type) ? type.constantize : nil
      found = klass ? klass.where(id: items.pluck(:item_id)).index_by(&:id) : {}
      [type, found]
    end
  end
end
