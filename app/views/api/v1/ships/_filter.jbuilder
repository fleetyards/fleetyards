# encoding: utf-8
# frozen_string_literal: true

json.name filter.name
json.value "#{filter.category}:#{filter.value}"
json.category filter.category
json.label "#{I18n.t("filter.ship.#{filter.category.underscore}.title")}: #{filter.name}"
