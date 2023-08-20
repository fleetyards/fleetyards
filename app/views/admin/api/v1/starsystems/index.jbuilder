# frozen_string_literal: true

json.array! @starsystems, partial: "admin/api/v1/starsystems/starsystem", as: :starsystem
