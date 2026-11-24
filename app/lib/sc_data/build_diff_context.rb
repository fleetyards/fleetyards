# frozen_string_literal: true

module ScData
  # What tells apart two entries of the same name, by record id: the ships a
  # component is fitted to, who makes an item, who gives a mission, where a place
  # is.
  class BuildDiffContext
    SHIPS_NAMED = 3

    def initialize(catalogue, entries, from:, to:)
      @catalogue = catalogue
      @ids = entries.map(&:id)
      @sources = [from, to]
    end

    def call
      case @catalogue
      when "components" then ships.merge(makers(::ComponentBuild, :component_id)) { |_id, fitted, _maker| fitted }
      when "equipment" then makers(::EquipmentBuild, :equipment_id)
      when "missions" then givers
      when "locations" then parents
      else {}
      end
    end

    # The newer build's answer, or the older one's for what it dropped.
    private def newest
      @sources.map { |source| yield({environment: source.environment, version: source.version}) }.reduce(:merge)
    end

    private def ships
      newest do |build|
        ::HardpointBuild.where(build).where(component_id: @ids)
          .joins(:hardpoint)
          .joins("INNER JOIN models ON models.id = hardpoints.parent_id AND hardpoints.parent_type = 'Model'")
          .merge(::Model.visible.active)
          .distinct.pluck(:component_id, "models.name")
          .group_by(&:first)
          .transform_values { |rows| named(rows.map(&:last).sort) }
      end
    end

    private def named(names)
      rest = names.size - SHIPS_NAMED
      shown = names.first(SHIPS_NAMED).join(", ")

      rest.positive? ? "#{shown} +#{rest}" : shown
    end

    private def makers(build_class, key)
      newest do |build|
        build_class.where(build).where(key => @ids).joins(:manufacturer).pluck(key, "manufacturers.name").to_h
      end
    end

    private def givers
      newest { |build| ::GameMissionBuild.where(build).where(game_mission_id: @ids).where.not(org_name: [nil, ""]).pluck(:game_mission_id, :org_name).to_h }
    end

    private def parents
      parent_ids = ::Location.where(id: @ids).where.not(parent_id: nil).pluck(:id, :parent_id).to_h
      names = newest { |build| ::LocationBuild.where(build).where(location_id: parent_ids.values).pluck(:location_id, :name).to_h }

      parent_ids.transform_values { |parent_id| names[parent_id] }.compact
    end
  end
end
