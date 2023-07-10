# frozen_string_literal: true

json.id model_upgrade.id
json.name model_upgrade.name

json.description model_upgrade.description
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: model_upgrade.store_image
  end
end
json.pledge_price model_upgrade.pledge_price&.to_f || nil

json.store_image model_upgrade.store_image.url
json.store_image_large model_upgrade.store_image.large.url
json.store_image_medium model_upgrade.store_image.medium.url
json.store_image_small model_upgrade.store_image.small.url
