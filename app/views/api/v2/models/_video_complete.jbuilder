# frozen_string_literal: true

json.cache! ['v2', video] do
  json.partial! 'api/v2/models/video', video: video
end
