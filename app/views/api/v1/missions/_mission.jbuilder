# frozen_string_literal: true

json.cache! ["v1", mission] do
  json.partial!("api/v1/missions/base", mission:)
end
