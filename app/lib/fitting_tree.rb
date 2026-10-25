# frozen_string_literal: true

# A ship's hardpoints as the browser works its figures out from them: the tree
# the hardpoints endpoint renders, as string-keyed hashes in snake case --
# `{name:, category:, component: {type:, size:, type_data:}, hardpoints: []}`.
#
# A ship as it comes is that tree as it stands, which is what its page shows.
# A loadout is the same tree with the fitting grafted in, as the loadout page
# grafts it (`graft` in `useComponentFitting.ts`): every hull slot a player
# fits is rebuilt from the loadout's slots, and the rest stays as the ship has
# it. Read by the same figures the browser reads, so the hangar and the ship
# page cannot disagree about a ship.
class FittingTree
  def self.stock(model)
    new(model).stock
  end

  def self.fitted(model, slots, crafted = {})
    new(model).fitted(slots, crafted)
  end

  def initialize(model)
    @model = model
  end

  # A level at a time, so a ship costs a query per level of nesting rather
  # than one per mount.
  def stock
    @stock ||= begin
      level = @model.hardpoints.game_files.in_build.includes(LoadoutSlots::FACTS_PRELOAD).to_a
      top = level.map { |hardpoint| hardpoint_node(hardpoint) }
      nodes = level.zip(top).to_h { |hardpoint, node| [hardpoint.id, node] }

      while level.any?
        level = ::Hardpoint.in_build.where(parent_type: "Hardpoint", parent_id: level.map(&:id))
          .includes(LoadoutSlots::FACTS_PRELOAD).to_a
        level.each do |hardpoint|
          node = hardpoint_node(hardpoint)
          nodes[hardpoint.parent_id]["hardpoints"] << node
          nodes[hardpoint.id] = node
        end
      end

      top
    end
  end

  # `crafted` are the loadout's crafted items by slot path.
  def fitted(slots, crafted = {})
    @crafted = crafted
    fitting = slots.fittable_hull.index_by(&:name)

    stock.map do |node|
      slot = fitting[node["name"]]
      slot ? slot_node(slots, slot, node) : node
    end
  end

  private def hardpoint_node(hardpoint)
    facts = hardpoint.facts

    {
      "name" => hardpoint.sc_name,
      "category" => facts.category,
      "component" => component_node(facts.component),
      "hardpoints" => []
    }
  end

  # A port inside a part names no category of its own; the ship's copy does,
  # and failing that the part in it.
  private def slot_node(slots, slot, original)
    content = slots.fitted(slot.path) || (slot.stock unless slot.module_slot? || slots.emptied?(slot.path))
    component = content if content.is_a?(Component)
    category = slot.facts.category.to_s
    category = original&.dig("category").presence || component&.category if category.blank? || category == "unknown"

    {
      "name" => slot.name,
      "category" => category,
      "component" => component_node(component, crafted_at(slot.path, component)),
      "hardpoints" => slots.children(slot).map do |child|
        slot_node(slots, child, original&.dig("hardpoints")&.find { |node| node["name"] == child.name })
      end
    }
  end

  private def component_node(component, figures = nil)
    return if component.nil?

    type_data = component.type_data.to_h.deep_stringify_keys

    {
      "name" => component.name,
      "type" => component.component_type,
      "size" => component.size,
      "type_data" => figures ? figures.type_data(type_data) : type_data
    }
  end

  # The part as crafted, where the loadout crafted the one in this slot and the
  # recipe is in the build; until then, as catalogued, as the page reads it.
  private def crafted_at(path, component)
    item = @crafted&.dig(path)
    return if item.nil? || component.nil? || item.item_id != component.id

    recipe = recipe_for(item.blueprint_id)
    return if recipe.nil? || recipe.craftable_type != "Component" || recipe.craftable_id != component.id

    CraftedFigures.new(recipe.cost_slots, item.crafted_qualities)
  end

  # Read as the loadout page reads a recipe: the build in force, else the last
  # one that described it, so a recipe a build retired still crafts the part it
  # made. Kept across the loadouts of the ship, which often share recipes.
  private def recipe_for(blueprint_id)
    @recipes ||= {}
    load_recipes(@crafted.values.map(&:blueprint_id) - @recipes.keys)
    @recipes[blueprint_id]
  end

  private def load_recipes(blueprint_ids)
    return if blueprint_ids.empty?

    ::Blueprint.where(id: blueprint_ids).includes(build: {cost_slots: :modifiers}).each do |blueprint|
      @recipes[blueprint.id] = blueprint.build || blueprint.last_build
    end
    blueprint_ids.each { |id| @recipes[id] ||= nil }
  end
end
