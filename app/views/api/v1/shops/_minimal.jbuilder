# frozen_string_literal: true

json.cache! ["v1", shop] do
  json.partial!("api/v1/shops/base", shop:)
  json.partial! "api/shared/dates", record: shop
end
