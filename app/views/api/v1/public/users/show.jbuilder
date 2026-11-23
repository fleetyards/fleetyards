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
    # The character file is downloadable by its token: shared only when the
    # user chose to show their own character.
    json.character_token(@user.public_character_face? ? outfit.character_face&.token : nil)
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

# Head and shoulders of the default outfit, always with the helmet on: the
# face stays private either way.
if @user.current_character_avatar_helmet
  json.character_portrait do
    json.partial! "api/v1/shared/file", record: @user, attr: :current_character_avatar_helmet
  end
else
  json.character_portrait nil
end

if (flagship = @user.vehicles.public.purchased.where(flagship: true).includes(:model).first)
  json.flagship do
    json.name flagship.name if flagship.name_visible?
    json.model_name flagship.model.name
    json.model_slug flagship.model.slug
    json.angled_view do
      json.partial! "api/v1/shared/file", record: flagship.model, attr: :angled_view
    end
  end
else
  json.flagship nil
end
