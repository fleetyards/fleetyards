# frozen_string_literal: true

json.array! @vehicles, partial: 'api/v1/vehicles/minimal_public', as: :vehicle
