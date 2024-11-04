# frozen_string_literal: true

json.id model_upgrade.id
json.name model_upgrade.name

json.description model_upgrade.description

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: model_upgrade.store_image
  end
end

json.pledge_price model_upgrade.pledge_price&.to_f || nil

json.partial! "api/shared/dates", record: model_upgrade
