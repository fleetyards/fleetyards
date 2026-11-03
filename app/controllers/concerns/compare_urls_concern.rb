# frozen_string_literal: true

# Where a comparison of each kind lives. Shared by the share endpoint and the
# short-link redirect, so a kind added to CompareImage::KINDS cannot lead one
# of them to the ship compare by default.
module CompareUrlsConcern
  extend ActiveSupport::Concern

  # An empty set lands on that kind's empty compare page.
  private def compare_url_for(kind, slugs)
    query = slugs.presence

    case kind
    when "models" then frontend_compare_url(models: query)
    when "components" then frontend_compare_components_url(components: query)
    when "equipment" then frontend_compare_equipment_url(equipment: query)
    else raise ArgumentError, "unknown compare kind: #{kind}"
    end
  end
end
