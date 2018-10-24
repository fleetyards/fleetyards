# frozen_string_literal: true

json.array! @celestial_objects, partial: 'api/v1/celestial_objects/minimal', as: :celestial_object
