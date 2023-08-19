# frozen_string_literal: true

json.array! @roadmap_items, partial: "api/v1/roadmap/roadmap_item", as: :item
