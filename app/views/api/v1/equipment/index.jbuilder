# frozen_string_literal: true

json.array! @equipment, partial: "api/v1/equipment/equipment", as: :equipment
