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

    # `provided` are the tags the ship and the ports above this one meet.
    def fits?(component, provided)
      LoadoutSlots.fits?(port, component, stock, provided)
    end

    # The tags the slot provides what sits in it and below: the part's own port
    # and the ship's copy of it do not always carry the same ones.
    def port_tags
      LoadoutSlots.port_tags(port) | (instance ? LoadoutSlots.port_tags(instance) : [])
    end
  end

  # The catalogue components a port takes, by name. Matched on the build's facts
  # in SQL, so a type the build changed is read as the build has it, then checked
  # once more in Ruby the way a save is. A port that names neither types nor a
  # category has nothing to match on and takes nothing.
  #
  # `candidates` keeps each kind's catalogue query for the next port asking the
  # same, so a whole tree costs a query per kind of part rather than per slot.
  # `stock` is what the slot came with, which a port inside a part does not
  # know itself: the ship's copy of the port holds it. `provided` are the tags
  # the ship and the ports above this one meet, as `tags_fit?` reads them.
  def self.options(port, candidates = {}, stock: port.facts.component, provided: nil)
    facts = port.facts
    types = types_taken(facts, stock)
    return [] if types.empty? && (facts.category.blank? || facts.category == "unknown")

    kind = types.any? ? [:component_type, types.sort] : category_kind(facts.category)
    # Resolving the served build costs queries of its own, so a tree resolves
    # it once for every kind of part it asks about.
    source = (candidates[:source] ||= Component.served_source)
    candidates[kind] ||= Component.joins(Component.current_facts_join(source)).catalogued
      .where(Component.fact_sql(kind.first).in(Array(kind.last)))
      .includes(:build, :last_build, ItemViews::DISPLAY_IMAGE_PRELOAD)
      .order(Component.fact_sql(:name))
      .to_a

    distinct(candidates[kind].select { |component| fits?(port, component, stock, provided) }, stock)
  end

  # A slot filed under a category its parts do not carry -- a mining laser's
  # slot is `mining_lasers`, the laser's own category `weapons` -- is matched on
  # the component types that category stands for.
  #
  # The SureGrip and ViseLock beams the game files type as SalvageHead are
  # among a tractor slot's candidates; `fits?` tells them from the heads.
  def self.category_kind(category)
    types = ::Hardpoint::TYPE_CATEGORIES.filter_map { |type, filed| type if filed.to_s == category }
    types << "SalvageHead" if category == "tractor_beams"

    types.any? ? [:component_type, types.sort] : [:category, category]
  end

  def self.filed_by_type?(category)
    ::Hardpoint::TYPE_CATEGORIES.value?(category.to_s.to_sym)
  end

  # The game files carry one part several times over -- a gas-cloud-resistant
  # AllStop, a gimbal mount per ship that uses it -- under one name and with
  # the same figures. A picker offers each once: the slot's own part where it
  # is one of them, else the plainest key.
  def self.distinct(components, stock = nil)
    components
      .group_by { |component| [component.name, component.size, component.grade, component.item_class, component.type_data.to_h] }
      .values
      .map { |same| same.find { |component| component.id == stock&.id } || same.min_by { |component| [component.sc_key.to_s.length, component.sc_key.to_s] } }
  end

  # A port that names no types (68 life-support slots, among others) is matched
  # on the category the slot was filed under instead.
  def self.fits?(port, component, stock = port.facts.component, provided = nil)
    facts = port.facts
    types = types_taken(facts, stock)
    kind_matches = if types.any?
      types.include?(component.component_type)
    elsif filed_by_type?(facts.category)
      ::Hardpoint::TYPE_CATEGORIES[::Hardpoint.filed_type(component)].to_s == facts.category
    else
      component.category == facts.category
    end
    return false unless kind_matches

    size = Integer(component.size, exception: false)
    return false if size.nil?
    return false if facts.min_size && size < facts.min_size
    return false if facts.max_size && size > facts.max_size

    component.id == stock&.id || tags_fit?(facts, component, stock, provided)
  end

  # Tags the game puts on nearly everything, which say nothing about a fit.
  GENERIC_TAGS = %w[flightReady].freeze

  # The game's tag rules, both ways round.
  #
  # The port's required tags have to be on the part -- how a ship's flight
  # blade port takes that ship's blades and no other's. A variant's port
  # carries its base ship's tags while its stock part carries the variant's (a
  # Vanguard Hoplite's blade port demands the Vanguard blade, its stock blade
  # names the Hoplite's), so where the stock part does not meet the port's tags
  # the stock part's own tags stand in for them -- unless it has none worth
  # reading, which would leave the port open to any ship's part.
  #
  # A part's required tags have to be met by the port, a port above it or the
  # ship: a Taurus tractor beam demands the Taurus's tag and fits no other
  # ship's gun port, and a Vanguard's nose guns demand the tag its nose mount's
  # port provides. `provided` are those of the ship and the ports above; without
  # them only the port's side is checked.
  def self.tags_fit?(facts, component, stock, provided)
    required = Array(facts.required_tags).compact_blank
    if stock && (required - Array(stock.tags)).any?
      own = Array(stock.tags).compact_blank - GENERIC_TAGS
      required = own if own.any?
    end
    return false if (required - Array(component.tags)).any?
    return true if provided.nil?

    (Array(component.required_tags).compact_blank - Array(facts.port_tags) - provided.to_a).empty?
  end

  # What the ship provides a part, read off what its stock parts demand: every
  # stock part fits in the game, so the tags they require that neither their own
  # port nor a port above it provides are there to be met. A tag a port provides
  # stays with that port and what sits below it; the Taurus's tractor beam port
  # is how its beam fits, not the ship.
  #
  # Below the hull, a stock part's own port can carry tags the ship's copy of it
  # does not (a Merlin's nose gun port), so both count.
  def self.ship_tags_for(model)
    tags = Set.new
    above = {}
    own = {}
    level = model.hardpoints.game_files.in_build.includes(PRELOAD).to_a
    while level.any?
      level.each do |hardpoint|
        provided = port_tags(hardpoint) | own.fetch([hardpoint.parent_id, hardpoint.sc_name], [])
        above[hardpoint.id] = above.fetch(hardpoint.parent_id, []) | provided
        tags.merge(Array(hardpoint.facts.component&.required_tags).compact_blank - above[hardpoint.id])
      end
      own = own_port_tags(level)
      level = Hardpoint.game_files.in_build
        .where(parent_type: "Hardpoint", parent_id: level.map(&:id))
        .includes(PRELOAD).to_a
    end
    tags
  end

  # The tags each stock part's own ports carry, by the ship's hardpoint holding
  # the part and the port's name.
  def self.own_port_tags(level)
    parts = level.filter_map { |hardpoint| [hardpoint.id, hardpoint.facts.component&.id] if hardpoint.facts.component }
    ports = Hardpoint.in_build.where(parent_type: "Component", parent_id: parts.map(&:last).uniq)
      .includes(PRELOAD).group_by(&:parent_id)
    parts.each_with_object({}) do |(holder_id, part_id), tags|
      ports.fetch(part_id, []).each { |port| tags[[holder_id, port.sc_name]] = port_tags(port) }
    end
  end

  def self.port_tags(port)
    Array(port.facts.port_tags).compact_blank
  end

  # A port naming a mount and a gun both takes the mount: the gun goes in the
  # mount's own port. Only where the ship came with a bare gun there does the
  # slot keep taking guns.
  def self.types_taken(facts, stock = facts.component)
    types = Array(facts.types).compact_blank
    return types unless types.include?("Turret") && types.size > 1
    return types if stock.present? && stock.component_type != "Turret"

    ["Turret"]
  end

  # The hull slots a player fits: the systems, the weapons and what holds them,
  # and the module slots, whose own slots open up once a module is fitted.
  # Doors, seats, thrusters and the rest are the shipwright's.
  HULL_CATEGORIES = %w[
    radar cooler lifesupport powerplant shieldgenerator quantumdrive controller
    weapons weapon_mounts turret missile_racks module
    mining_lasers tractor_beams missiles bombs
  ].freeze

  # What a slot reads: the port's build and the stock part, with the facts of
  # that part.
  PRELOAD = {
    component: [:build, :last_build, ItemViews::DISPLAY_IMAGE_PRELOAD],
    build: {component: [:build, :last_build, ItemViews::DISPLAY_IMAGE_PRELOAD]}
  }.freeze

  # `items` are `{slot_path:, item_type:, item_id:}` hashes, as a loadout's
  # `item_list` holds them.
  def initialize(model, items = [])
    @model = model
    @items = items.index_by { |item| item[:slot_path] }
    @below = {}
    @ports = {}
    @candidates = {}
    @swappable = {}
    @provided = {}
  end

  def ship_tags
    @ship_tags ||= LoadoutSlots.ship_tags_for(@model)
  end

  def fits?(slot, component)
    slot.fits?(component, provided(slot))
  end

  # The tags a part in `slot` may demand: the ship's, and those of its port and
  # every port above it.
  def provided(slot)
    parent_path = slot.path.rpartition("/").first
    above = if parent_path.empty?
      ship_tags
    else
      @provided[parent_path] ||= self[parent_path]&.then { |parent| provided(parent) } || ship_tags
    end
    above | slot.port_tags
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
    @fittable_hull ||= hull.select do |slot|
      next false unless HULL_CATEGORIES.include?(slot.facts.category)
      next true unless slot.facts.category == "controller"

      # Shield, missile and weapon controllers are ship internals; the flight
      # blade is the one controller a player swaps, as in the catalogue.
      Component::CATALOGUED_CONTROLLER_TYPES.include?(slot.stock&.component_type) ||
        Array(slot.facts.types).intersect?(Component::CATALOGUED_CONTROLLER_TYPES)
    end.tap { |slots| prefetch_below(slots) }
  end

  # Whether anything but the part the slot came with fits it, so a slot with
  # nothing to choose from is not offered as a choice.
  def swappable?(slot)
    return false unless slot.editable?

    # By port and stock: two mounts share one port record but can hold
    # different guns.
    provided = provided(slot)
    key = [slot.port.id, slot.stock&.id, provided.sort]
    @swappable.fetch(key) do
      @swappable[key] = LoadoutSlots.options(slot.port, @candidates, stock: slot.stock, provided:)
        .any? { |component| component.id != slot.stock&.id }
    end
  end

  # Whether the slot at `path` hangs off a hull slot a player fits at all.
  def fittable?(path)
    @fittable_roots ||= fittable_hull.map(&:name).to_set
    @fittable_roots.include?(path.partition("/").first)
  end

  def children(slot)
    below(slot).values
  end

  # Whether anything sits in the slot at `path` -- fitted there, or its stock
  # component left in place -- so a slot beneath it exists.
  def occupied?(path)
    return !emptied?(path) if @items.key?(path)

    slot = self[path]
    slot.present? && !slot.module_slot? && slot.stock.present?
  end

  # Taken out by the loadout, stock part and all.
  def emptied?(path)
    @items[path]&.dig(:item_type) == VehicleLoadoutItem::EMPTY
  end

  def fitted(path)
    item = @items[path]
    return if item.nil?

    records.dig(item[:item_type], item[:item_id])
  end

  private def hull_slots
    @hull_slots ||= @model.hardpoints.game_files.in_build.includes(PRELOAD)
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
    prefetch_ports([owner])
    @ports[port_owner_key(owner)]
  end

  # A whole tree's ports, a level at a time: one query per kind of owner per
  # level rather than two per slot.
  private def prefetch_below(slots)
    level = slots
    while level.any?
      prefetch_ports(level.flat_map { |slot| [fitted(slot.path), slot.stock, slot.instance] }.compact)
      level = level.flat_map { |slot| children(slot) }
    end
  end

  private def prefetch_ports(owners)
    missing = owners.reject { |owner| @ports.key?(port_owner_key(owner)) }.uniq { |owner| port_owner_key(owner) }

    missing.group_by { |owner| owner.class.base_class.name }.each do |type, list|
      found = Hardpoint.in_build.where(parent_type: type, parent_id: list.map(&:id)).includes(PRELOAD).group_by(&:parent_id)
      list.each { |owner| @ports[port_owner_key(owner)] = found.fetch(owner.id, []) }
    end
  end

  private def port_owner_key(owner)
    [owner.class.base_class.name, owner.id]
  end

  private def records
    @records ||= @items.values.group_by { |item| item[:item_type] }.to_h do |type, items|
      klass = (VehicleLoadoutItem::ITEM_TYPES - [VehicleLoadoutItem::EMPTY]).include?(type) ? type.constantize : nil
      scope = (klass == Component) ? klass.includes(:build, :last_build, ItemViews::DISPLAY_IMAGE_PRELOAD) : klass
      found = klass ? scope.where(id: items.pluck(:item_id)).index_by(&:id) : {}
      [type, found]
    end
  end
end
