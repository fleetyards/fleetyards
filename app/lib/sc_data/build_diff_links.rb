# frozen_string_literal: true

module ScData
  # Where each entry of a comparison leads, by record id. A record the build the
  # reader is on does not have has no page there, so it gets no link.
  class BuildDiffLinks
    SUBJECTS = {
      "models" => "Model", "loadouts" => "Model", "components" => "Component", "equipment" => "Equipment",
      "commodities" => "Commodity", "blueprints" => "Blueprint", "missions" => "GameMission",
      "factions" => "Faction", "locations" => "Location"
    }.freeze

    def initialize(catalogue, entries)
      @subject = SUBJECTS[catalogue]&.constantize
      @ids = entries.map(&:id)
    end

    def call
      return {} if @subject.nil?

      scope = (@subject == ::Model) ? ::Model.visible.active : @subject.current_version

      scope.where(id: @ids).pluck(:id, :slug).to_h.compact
    end
  end
end
