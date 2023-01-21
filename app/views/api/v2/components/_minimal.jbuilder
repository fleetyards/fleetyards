# frozen_string_literal: true

json.cache! ["v2", component] do
  json.partial!("api/v2/components/base", component:)
  json.partial! "api/shared/dates", record: component
end
