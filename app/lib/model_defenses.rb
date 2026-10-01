# frozen_string_literal: true

# Every catalogue ship's armor and shields, as the build in force installs them.
#
# Read from the slots rather than from the model, because that is where the
# build puts them: nearly always straight on the ship, but a few shield
# generators sit one level down, inside another slot. Both levels are asked for
# at once so the whole catalogue costs a handful of queries instead of one
# loadout per ship.
class ModelDefenses
  CATEGORIES = %w[armor shieldgenerator].freeze

  Row = Struct.new(:model, :armor, :shields)

  def self.call
    new.call
  end

  def call
    models = Model.visible.active.includes(:manufacturer, :build, :last_build).order(name: :asc).index_by(&:id)
    defenses = collect(models.keys)

    models.values.filter_map do |model|
      entry = defenses[model.id]
      next if entry.nil?

      Row.new(model:, armor: entry[:armor], shields: entry[:shields])
    end
  end

  private def collect(model_ids)
    top_level = Hardpoint.in_build.where(parent_type: "Model", parent_id: model_ids)
    nested = Hardpoint.in_build.where(parent_type: "Hardpoint", parent_id: top_level.select(:id))

    slots = top_level.or(nested)
      .merge(categorised)
      .includes(build: {component: %i[build last_build]}, component: %i[build last_build])
      .to_a

    owners = Hardpoint
      .where(id: slots.select { |slot| slot.parent_type == "Hardpoint" }.map(&:parent_id))
      .pluck(:id, :parent_id)
      .to_h

    slots.each_with_object({}) do |slot, defenses|
      facts = slot.facts
      data = facts.component&.type_data
      next if data.blank?

      model_id = (slot.parent_type == "Model") ? slot.parent_id : owners[slot.parent_id]
      entry = defenses[model_id] ||= {armor: nil, shields: []}

      case facts.category
      when "armor" then entry[:armor] ||= data
      when "shieldgenerator" then entry[:shields] << data
      end
    end
  end

  # A narrowing only: the column and the build can disagree about a slot, and
  # the build wins, so each slot is checked against its facts afterwards.
  private def categorised
    Hardpoint.where(category: CATEGORIES)
      .or(Hardpoint.where(id: HardpointBuild.where(category: CATEGORIES).select(:hardpoint_id)))
  end
end
