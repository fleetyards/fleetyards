# frozen_string_literal: true

json.array! @item_problems do |problem|
  json.slot_path problem[:slot_path]
  json.item_type problem[:item_type]
  json.item_id problem[:item_id] if problem[:item_id]
  json.item_name @item_names[problem[:item_id]] if @item_names[problem[:item_id]]
  json.code problem[:code]
end
