# frozen_string_literal: true

json.id video.id
json.url video.video_url
json.video_id video.video_id
json.type video.video_type
json.partial! 'api/shared/dates', record: video
