# encoding: utf-8
# frozen_string_literal: true

json.array! @filters, partial: 'api/v1/ships/filter', as: :filter
