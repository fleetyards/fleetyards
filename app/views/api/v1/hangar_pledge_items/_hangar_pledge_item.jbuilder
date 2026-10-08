# frozen_string_literal: true

json.id hangar_pledge_item.id
json.rsi_pledge_id hangar_pledge_item.rsi_pledge_id
json.kind hangar_pledge_item.kind
json.name hangar_pledge_item.name
json.quantity hangar_pledge_item.quantity
json.image hangar_pledge_item.image_url if hangar_pledge_item.image_url.present?
json.standalone hangar_pledge_item.standalone?
json.meltable hangar_pledge_item.meltable
json.pledge_created_on hangar_pledge_item.pledge_created_on.iso8601 if hangar_pledge_item.pledge_created_on.present?
json.melt_value hangar_pledge_item.melt_value.to_f unless hangar_pledge_item.melt_value.nil?
json.pledge_name hangar_pledge_item.pledge_name if hangar_pledge_item.pledge_name.present?
json.pledge_value hangar_pledge_item.pledge_value.to_f unless hangar_pledge_item.pledge_value.nil?
json.partial! "api/shared/dates", record: hangar_pledge_item
