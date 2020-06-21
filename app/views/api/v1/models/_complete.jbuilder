# frozen_string_literal: true

json.cache! ['v1', model] do
  json.partial! 'api/v1/models/base', model: model
  json.erkuls_slug model.erkuls_slug
  json.docks do
    json.array! model.dock_counts, partial: 'api/v1/models/dock', as: :dock_count
  end
  json.hardpoints do
    json.array! model.hardpoints.includes(:component).undeleted, partial: 'api/v1/models/hardpoint', as: :hardpoint
  end
  json.sold_at do
    json.array! model.sold_at, partial: 'api/v1/models/shop', as: :shop_commodity
  end
  json.bought_at do
    json.array! model.bought_at, partial: 'api/v1/models/shop', as: :shop_commodity
  end
  json.rental_at do
    json.array! model.rental_at, partial: 'api/v1/models/shop', as: :shop_commodity
  end
  json.partial! 'api/shared/dates', record: model
end
