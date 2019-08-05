# frozen_string_literal: true

json.array! @commodity_types, partial: 'api/shared/filter', as: :filter
