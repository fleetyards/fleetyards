# frozen_string_literal: true

json.holders shares do |share|
  if share.holder.present?
    json.holder do
      json.id share.holder.id
      json.username share.holder.username
    end
  else
    json.holder nil
  end
  json.net_quantity share.net_quantity.to_f
end
