# frozen_string_literal: true

json.cache! ['v1', model] do
  json.partial! 'api/v1/models/base', model: model
  json.manufacturer do
    json.null! if model.manufacturer.blank?
    json.partial! 'api/v1/manufacturers/base', manufacturer: model.manufacturer if model.manufacturer.present?
  end
  json.hardpoints do
    json.array! model.hardpoints, partial: 'api/v1/models/hardpoint', as: :hardpoint
  end
  if params[:without_images].blank?
    json.images do
      json.array! model.images.enabled, partial: 'api/v1/images/base', as: :image
    end
  end
  if params[:without_videos].blank?
    json.videos do
      json.array! model.videos, partial: 'api/v1/models/video', as: :video
    end
  end
  json.partial! 'api/shared/dates', record: model
end
