# frozen_string_literal: true

json.array! @filters, partial: 'api/v1/shared/filter', as: :filter
