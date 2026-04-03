# frozen_string_literal: true

json.id model_upgrade.id
json.name model_upgrade.name
json.active model_upgrade.active
json.hidden model_upgrade.hidden

json.description model_upgrade.description

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/file", record: model_upgrade, attr: :store_image
  end
end

json.pledge_price model_upgrade.pledge_price&.to_f || nil

json.partial! "api/shared/dates", record: model_upgrade
