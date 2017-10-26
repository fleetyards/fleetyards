# encoding: utf-8
# frozen_string_literal: true

json.array! @models, partial: 'api/v1/fleets/model', as: :model
