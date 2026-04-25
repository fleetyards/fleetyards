# frozen_string_literal: true

module RansackHelper
  def sorting_params(model, sorts, fallback = nil)
    sorting_items = sorts.is_a?(Array) ? sorts : [sorts] # Ensure sorts is always an array

    sorting_items.filter_map do |sort|
      sort.underscore if model::ALLOWED_SORTING_PARAMS.include?(sort)
    end.presence || fallback || model::DEFAULT_SORTING_PARAMS
  end

  # Ransack accepts both "s" and "sorts" for sorting. This helper
  # normalizes the query params so that sorting_params always has data
  # regardless of which key the client used.
  def normalize_sort_params(query_params)
    query_params["sorts"] ||= query_params.delete("s") if query_params["s"].present?
  end
end
