# frozen_string_literal: true

# The ship's model is in the key because a ship inventory without a picture of
# its own is shown as its ship. Its attachments are in there too: attaching or
# replacing artwork writes an Attachment row and leaves the model untouched --
# `use_rsi_image` does exactly that -- so the model alone would keep serving the
# picture the ship used to have.
model = hangar_inventory.vehicle&.model

json.cache! ["v1", hangar_inventory, model, *model&.image_attachments].compact do
  json.partial!("api/v1/shared/inventory", inventory: hangar_inventory)
end
