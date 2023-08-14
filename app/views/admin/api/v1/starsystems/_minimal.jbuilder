# frozen_string_literal: true

json.cache! ["v1", starsystem] do
  json.partial!("admin/api/v1/starsystems/base", starsystem:)
  json.partial! "api/shared/dates", record: starsystem
end
