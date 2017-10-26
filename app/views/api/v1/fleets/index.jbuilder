# encoding: utf-8
# frozen_string_literal: true

json.array! @fleets, partial: 'api/v1/fleets/base', as: :fleet
