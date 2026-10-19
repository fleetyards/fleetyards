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

    # Counted the way the sync modal counts a run while it reads, so a new run
    # can be measured against this one: ships, modules and upgrades per item,
    # the rest once per name in a pledge, as the sync stores them.
    # A component RSI lists is a module or a ship part, told apart as the sync
    # tells them apart.
    COUNTED_PER_ITEM = %w[ship component upgrade].freeze
    READ_KINDS = %w[ship component upgrade skin flair equipment ccu extra ship_component].freeze

    def read_summary
      items = Array(input)
      counts = READ_KINDS.index_with do |kind|
        of_kind = items.select { |item| read_kind(item) == kind }
        next of_kind.size if COUNTED_PER_ITEM.include?(kind)

        of_kind.map { |item| "#{item["id"]}:#{item["name"].to_s.strip}" }.uniq.size
      end

      {
        finished_at: finished_at,
        pages: items.filter_map { |item| item["page"] }.max,
        total: counts.values.sum,
        counts:
      }
    end

    private def read_kind(item)
      return item["type"] unless item["type"] == "component"

      ::HangarModuleMapping.module?(item["name"]) ? "component" : "ship_component"
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
