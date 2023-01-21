# frozen_string_literal: true

json.array! @vehicles, partial: "api/v2/hangar/vehicles/export", as: :vehicle
