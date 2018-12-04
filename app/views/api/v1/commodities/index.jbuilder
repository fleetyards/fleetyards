# frozen_string_literal: true

json.array! @commodities, partial: 'api/v1/commodities/minimal', as: :commodity
