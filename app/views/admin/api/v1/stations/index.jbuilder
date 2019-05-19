# frozen_string_literal: true

json.array! @stations, partial: 'admin/api/v1/stations/minimal', as: :station
