# frozen_string_literal: true

json.array! @vehicles, partial: "api/v1/public/vehicles/vehicle", as: :vehicle
