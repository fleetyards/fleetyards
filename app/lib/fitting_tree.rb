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

  def self.fitted(model, slots)
    new(model).fitted(slots)
  end

  def initialize(model)
    @model = model
  end

  def stock
    @stock ||= hardpoint_nodes(@model.hardpoints.game_files.in_build)
  end

  def fitted(slots)
    fitting = slots.fittable_hull.index_by(&:name)

    stock.map do |node|
      slot = fitting[node["name"]]
      slot ? slot_node(slots, slot, node) : node
    end
  end

  private def hardpoint_nodes(scope)
    scope.includes(LoadoutSlots::PRELOAD).map do |hardpoint|
      facts = hardpoint.facts

      {
        "name" => hardpoint.sc_name,
        "category" => facts.category,
        "component" => component_node(facts.component),
        "hardpoints" => hardpoint_nodes(hardpoint.hardpoints.in_build)
      }
    end
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
      "component" => component_node(component),
      "hardpoints" => slots.children(slot).map do |child|
        slot_node(slots, child, original&.dig("hardpoints")&.find { |node| node["name"] == child.name })
      end
    }
  end

  private def component_node(component)
    return if component.nil?

    {
      "name" => component.name,
      "type" => component.component_type,
      "size" => component.size,
      "type_data" => component.type_data.to_h.deep_stringify_keys
    }
  end
end
