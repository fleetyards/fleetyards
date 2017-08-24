# encoding: utf-8
# frozen_string_literal: true

json.name hardpoint.name
json.hardpoint_class hardpoint.hardpoint_class
json.rating hardpoint.rating
json.max_size hardpoint.max_size
json.quantity hardpoint.quantity
json.categoryName hardpoint.category.name
json.categorySlug hardpoint.category.slug
json.component do
  json.partial! 'api/v1/ships/component', component: hardpoint.component if hardpoint.component.present?
end
