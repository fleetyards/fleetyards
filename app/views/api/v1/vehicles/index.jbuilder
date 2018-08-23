# frozen_string_literal: true

json.array! @vehicles.to_a.uniq, partial: 'api/v1/vehicles/base', as: :vehicle
