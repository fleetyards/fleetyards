# encoding: utf-8
# frozen_string_literal: true

json.array! @categories, partial: 'api/v1/components/category', as: :category
