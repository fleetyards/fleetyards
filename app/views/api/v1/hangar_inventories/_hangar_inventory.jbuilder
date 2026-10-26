# frozen_string_literal: true

# The ship's model is in the key because a ship inventory without a picture of
# its own is shown as its ship. Its attachments are in there too: attaching or
# replacing artwork writes an Attachment row and leaves the model untouched --
# `use_rsi_image` does exactly that -- so the model alone would keep serving the
# picture the ship used to have.
model = hangar_inventory.vehicle&.model

# The linked place too: its name and slug are in the fragment, and renaming it
# does not touch the inventory. So is the ship, for its name and whether it is
# on the wishlist.
json.cache! ["v5", hangar_inventory, hangar_inventory.vehicle, model, *model&.image_attachments, hangar_inventory.linked_location&.link_cache_key].compact do
  json.partial!("api/v1/shared/inventory", inventory: hangar_inventory)
end
