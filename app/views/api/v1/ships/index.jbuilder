# encoding: utf-8
# frozen_string_literal: true
json.array! @ships, partial: 'api/v1/ships/show', as: :ship
