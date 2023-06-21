# frozen_string_literal: true

json.array! @hardpoints, partial: "api/v1/model_hardpoints/base", as: :hardpoint
