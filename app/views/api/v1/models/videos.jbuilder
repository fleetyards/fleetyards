# frozen_string_literal: true

json.array! @videos, partial: 'api/v1/models/video_complete', as: :video
