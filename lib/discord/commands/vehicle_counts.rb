# frozen_string_literal: true

module Discord
  module Commands
    # Ships grouped by model name, the shape every hangar answer takes. An embed
    # caps out long before a large hangar does, so the list is truncated and the
    # link carries the rest.
    module VehicleCounts
      MAX_SHIPS = 10

      private def model_counts(scope)
        scope.joins(:model).group("models.name").order("count_all desc, models.name asc").count
      end

      private def shown_counts(counts)
        counts.first(MAX_SHIPS)
      end

      private def count_lines(counts)
        shown_counts(counts).map { |name, count| (count > 1) ? "• #{count}× #{name}" : "• #{name}" }
      end

      private def omitted_count(counts)
        counts.size - shown_counts(counts).size
      end
    end
  end
end
