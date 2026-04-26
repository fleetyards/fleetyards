# frozen_string_literal: true

json.array! @positions, partial: "api/v1/model_positions/model_position", as: :model_position
