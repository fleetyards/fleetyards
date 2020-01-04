# frozen_string_literal: true

json.partial! 'api/v1/vehicles/base', vehicle: vehicle
json.partial! 'api/shared/dates', record: vehicle
