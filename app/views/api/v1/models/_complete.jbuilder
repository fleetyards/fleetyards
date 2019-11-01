# frozen_string_literal: true

json.cache! ['v1', model] do
  json.partial! 'api/v1/models/base', model: model
  json.erkuls_slug model.erkuls_slug
  json.docks do
    json.array! model.dock_counts, partial: 'api/v1/models/dock', as: :dock_count
  end
  json.hardpoints do
    json.array! model.hardpoints, partial: 'api/v1/models/hardpoint', as: :hardpoint
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
  unless without_images?
    json.images do
      json.array! model.images.enabled, partial: 'api/v1/images/base', as: :image
    end
  end
  unless without_videos?
    json.videos do
      json.array! model.videos, partial: 'api/v1/models/video', as: :video
    end
  end
  json.partial! 'api/shared/dates', record: model
end
