# frozen_string_literal: true

json.array! @filters, partial: 'api/v1/models/filter', as: :filter
