# frozen_string_literal: true

module Cleanup
  # Components are keyed on (sc_key, version), so every imported build adds a
  # fresh row per component and nothing ever took the old ones away. The rows
  # cannot simply be dropped: a saved vehicle loadout points at the component it
  # was built with, and that reference is what keeps the loadout meaning what
  # its owner chose.
  #
  # So this keeps the current build and whatever players still reference, and
  # takes the rest.
  class ComponentVersionsJob < ::Cleanup::BaseJob
    Result = Struct.new(:removed, :kept_for_loadouts) do
      def to_s
        "removed=#{removed} kept_for_loadouts=#{kept_for_loadouts}"
      end
    end

    def perform
      version = Rails.configuration.sc_data[:version]

      # Before the current build has been imported every row looks stale, and
      # the table would be emptied. Nothing to clean up until it lands.
      return if version.blank? || Component.where(version:).none?

      referenced = VehicleLoadoutHardpoint.where.not(component_id: nil).select(:component_id)
      stale = Component.where.not(version:).where.not(id: referenced)

      result = Result.new(removed: 0, kept_for_loadouts: Component.where.not(version:).where(id: referenced).count)

      # model_hardpoint_loadouts carries a component_id with no foreign key and
      # no association back from Component, so nothing would clear it.
      ModelHardpointLoadout.where(component_id: stale.select(:id)).update_all(component_id: nil)

      # Destroyed rather than deleted: a component owns its sub-hardpoints, and
      # the hardpoints fitted with it have a foreign key that has to be cleared
      # before the row can go.
      stale.find_each do |component|
        component.destroy
        result.removed += 1
      end

      Rails.logger.info("[Cleanup::ComponentVersionsJob] #{result}")

      result
    end
  end
end
