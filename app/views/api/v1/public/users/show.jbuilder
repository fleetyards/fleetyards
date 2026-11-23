# frozen_string_literal: true

json.partial! "api/v1/public/users/user", user: @user

# Outside the cached fragment: it depends on who is reading. Absent rather than
# false when the reader gets no answer, as on every roster.
online = online_status_for(@user) if @show_presence
json.online online unless online.nil?

# Outside the cached fragment too: saving the outfit's pieces does not touch
# the user.
if (outfit = @user.default_outfit)
  json.character do
    json.body outfit.body
    json.held_weapon outfit.held_weapon
    json.character_token outfit.character_face&.token
    json.items outfit.items.includes(:equipment) do |item|
      json.slot item.slot
      json.slug item.equipment.slug
    end
    json.stored_items outfit.stored_items.includes(:equipment) do |item|
      json.holder item.holder
      json.slug item.equipment.slug
      json.quantity item.quantity
    end
  end
else
  json.character nil
end
