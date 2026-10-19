# frozen_string_literal: true

# Which components a recipe makes in the build being served, for a loadout's
# slots to offer crafting on: one query per request, however many slots and
# candidates the response names.
module CraftableComponentsConcern
  extend ActiveSupport::Concern

  included do
    helper_method :craftable_component_ids
  end

  private def craftable_component_ids
    @craftable_component_ids ||= Blueprint.readable_builds(Blueprint.served_source)
      .where(craftable_type: "Component")
      .distinct
      .pluck(:craftable_id)
      .to_set
  end
end
