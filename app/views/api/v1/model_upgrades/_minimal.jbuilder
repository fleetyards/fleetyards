# frozen_string_literal: true

json.cache! ['v1', model_upgrade] do
  json.partial! 'api/v1/model_upgrades/base', model_upgrade: model_upgrade
  json.partial! 'api/shared/dates', record: model_upgrade
end
