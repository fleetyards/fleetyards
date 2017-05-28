# encoding: utf-8
# frozen_string_literal: true

json.cache! ['v1', @ship] do
  json.partial! 'api/v1/ships/complete', ship: @ship
end
