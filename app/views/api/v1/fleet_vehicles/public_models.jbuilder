# frozen_string_literal: true

json.array! @models, partial: 'api/v1/fleet_vehicles/public_model', as: :model
