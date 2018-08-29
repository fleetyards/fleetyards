# frozen_string_literal: true

json.array! @classifications, partial: 'api/v1/models/filter', as: :filter
