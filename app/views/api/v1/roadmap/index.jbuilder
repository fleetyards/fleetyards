# frozen_string_literal: true

json.array! @roadmap_items, partial: 'api/v1/roadmap/minimal', as: :item
