# frozen_string_literal: true

json.array! @hardpoints, partial: "api/v1/hardpoints/hardpoint", as: :hardpoint
