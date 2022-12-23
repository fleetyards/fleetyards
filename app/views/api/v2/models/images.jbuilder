# frozen_string_literal: true

json.partial! 'api/shared/pagination_metadata', scope: @images, model: Image
json.items do
  json.array! @images, partial: 'api/v2/images/complete', as: :image
end
