# frozen_string_literal: true

json.array! @weapons, partial: "api/v1/equipment/equipment", as: :equipment
