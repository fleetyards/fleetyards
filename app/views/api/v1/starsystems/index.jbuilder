# frozen_string_literal: true

json.array! @starsystems, partial: 'api/v1/starsystems/minimal', as: :starsystem
