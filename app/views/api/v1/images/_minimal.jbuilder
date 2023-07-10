# frozen_string_literal: true

json.cache! ["v1", image] do
  json.partial!("api/v1/images/base", image:)
  json.partial! "api/shared/dates", record: image
end
