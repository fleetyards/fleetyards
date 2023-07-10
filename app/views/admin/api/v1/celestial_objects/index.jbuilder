# frozen_string_literal: true

json.array! @celestial_objects, partial: "admin/api/v1/celestial_objects/minimal", as: :celestial_object
