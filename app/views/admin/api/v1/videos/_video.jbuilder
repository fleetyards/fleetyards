# frozen_string_literal: true

json.cache! ["v1", video] do
  json.partial!("admin/api/v1/videos/base", video:)
end
