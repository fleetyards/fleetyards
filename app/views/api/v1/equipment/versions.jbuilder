# frozen_string_literal: true

json.array! @versions, partial: "api/v1/equipment/equipment", as: :equipment
