# frozen_string_literal: true

json.array! @hardpoints,
  partial: "api/v1/hardpoints/base",
  as: :hardpoint,
  cached: ->(hardpoint) { ["v1", hardpoint, hardpoint.component] }
