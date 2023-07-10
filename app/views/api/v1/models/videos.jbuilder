# frozen_string_literal: true

json.array! @videos, partial: "api/v1/videos/minimal", as: :video
