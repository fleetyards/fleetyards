# frozen_string_literal: true

json.array! @sizes, partial: 'api/v1/models/filter', as: :filter
