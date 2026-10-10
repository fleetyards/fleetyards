# frozen_string_literal: true

module Imports
  class HangarSync < ::Import
    belongs_to :user

    # The vehicle keys hold ids, so they are resolved to names here. A vehicle
    # deleted since the run simply drops out: there is no longer a ship to name,
    # and inventing a placeholder would be worse than a shorter list.
    def result_details
      {
        imported: vehicle_names(output&.dig("imported_vehicles")),
        found: vehicle_names(output&.dig("found_vehicles")),
        moved_to_wanted: vehicle_names(output&.dig("moved_vehicles_to_wanted")),
        # Already names: the rows they came from are gone, so there is nothing
        # left to resolve an id against.
        deleted: Array(output&.dig("deleted_vehicles")),
        grouped: vehicle_names(output&.dig("grouped_vehicles")),
        unchanged: vehicle_names(output&.dig("unchanged_vehicles")),
        missing: Array(output&.dig("missing_models")),
        missing_components: Array(output&.dig("missing_components")),
        missing_upgrades: Array(output&.dig("missing_upgrades"))
      }.reject { |_key, names| names.empty? }
    end

    private def vehicle_names(ids)
      return [] if ids.blank?

      Vehicle.where(id: ids).includes(:model).map do |vehicle|
        vehicle.name.presence || vehicle.model&.name
      end.compact.sort
    end

    # The pages the parser read only in part, kept in `import_data` as the raw
    # RSI data the sync came from: the admin imports page shows it as is.
    def unread_pages
      @unread_pages ||= begin
        data = import_data.present? ? JSON.parse(import_data) : {}
        data.is_a?(Hash) ? Array(data["unread_pages"]) : []
      rescue JSON::ParserError
        []
      end
    end

    def notify_admin
      # don't notify on hangar sync
    end
  end
end
