# frozen_string_literal: true

json.array! @items, partial: 'api/v1/progress_tracker_items/minimal', as: :item
