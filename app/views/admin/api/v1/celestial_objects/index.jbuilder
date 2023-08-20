# frozen_string_literal: true

json.array! @celestial_objects, partial: "admin/api/v1/celestial_objects/celestial_object", as: :celestial_object
