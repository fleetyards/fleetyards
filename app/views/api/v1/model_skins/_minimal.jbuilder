# frozen_string_literal: true

json.cache! ['v1', model_skin] do
  json.partial! 'api/v1/model_skins/base', model_skin: model_skin
  json.partial! 'api/shared/dates', record: model_skin
end
