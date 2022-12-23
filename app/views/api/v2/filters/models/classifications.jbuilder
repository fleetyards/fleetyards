# frozen_string_literal: true

json.array! @classifications, partial: 'api/shared/filter', as: :filter
