# frozen_string_literal: true

json.array! @model_hardpoints, partial: "api/v1/model_hardpoints/model_hardpoint", as: :hardpoint
