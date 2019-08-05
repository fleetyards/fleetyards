# frozen_string_literal: true

json.array! @production_states, partial: 'api/shared/filter', as: :filter
