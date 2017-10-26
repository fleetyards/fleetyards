# encoding: utf-8
# frozen_string_literal: true

json.array! @vehicles, partial: 'api/v1/vehicles/show', as: :vehicle
