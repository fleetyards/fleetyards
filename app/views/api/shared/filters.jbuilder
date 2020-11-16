# frozen_string_literal: true

json.array! @filters, partial: 'api/shared/filter', as: :filter
