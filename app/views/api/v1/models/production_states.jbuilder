# frozen_string_literal: true

json.array! @production_states, partial: 'api/v1/models/filter', as: :filter
