# encoding: utf-8
# frozen_string_literal: true

json.cache! ['v1', image] do
  json.partial! 'api/v1/images/base', image: image
  json.partial! 'api/shared/dates', record: image
end
