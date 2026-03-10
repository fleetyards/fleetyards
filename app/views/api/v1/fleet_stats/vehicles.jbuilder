# frozen_string_literal: true

json.total @quick_stats.total
json.classifications do
  json.array! @quick_stats.classifications, partial: "api/v1/vehicles/classification_quick_stats", as: :classification_quick_stats
end
json.metrics do
  json.total_money @quick_stats.metrics[:total_money]
  json.total_credits @quick_stats.metrics[:total_credits]
  json.total_ingame_value @quick_stats.metrics[:total_ingame_value]
  json.total_min_crew @quick_stats.metrics[:total_min_crew]
  json.total_max_crew @quick_stats.metrics[:total_max_crew]
  json.total_cargo @quick_stats.metrics[:total_cargo]
  json.largest_ship @quick_stats.metrics[:largest_ship]
  json.smallest_ship @quick_stats.metrics[:smallest_ship]
  json.average_pledge_price @quick_stats.metrics[:average_pledge_price]
  json.flight_ready_count @quick_stats.metrics[:flight_ready_count]
  json.unique_models_count @quick_stats.metrics[:unique_models_count]
  json.manufacturer_count @quick_stats.metrics[:manufacturer_count]
  json.missing_classifications @quick_stats.metrics[:missing_classifications]
  json.wishlist_total_money @quick_stats.metrics[:wishlist_total_money]
  json.wishlist_total_credits @quick_stats.metrics[:wishlist_total_credits]
end
