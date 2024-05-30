# frozen_string_literal: true

json.items do
  json.array! @videos, partial: "api/v1/videos/video", as: :video
end
json.partial! "api/shared/meta", result: @videos
