# frozen_string_literal: true

json.array! @stock do |item|
  json.name item.name
  json.category item.category
  json.unit item.unit
  if item.respond_to?(:quality_min)
    json.quality_min item.quality_min
    json.quality_max item.quality_max
  else
    json.quality item.quality
  end
  json.net_quantity item.net_quantity.to_f

  if item.respond_to?(:inventory_name) && item.inventory_name.present?
    json.inventory do
      json.name item.inventory_name
      json.slug item.inventory_slug
    end
  end
end
