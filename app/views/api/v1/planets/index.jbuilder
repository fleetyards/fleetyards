# frozen_string_literal: true

json.array! @planets, partial: 'api/v1/planets/minimal', as: :planet
