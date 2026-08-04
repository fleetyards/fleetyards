# frozen_string_literal: true

# Attaches a store image bundled at db/seeds/images/<filename> to a record's `store_image`,
# unless one is already attached. Used for manually-seeded models/paints that aren't covered
# by the RSI/hangar image importers.
attach_store_image = lambda do |record, filename|
  path = Rails.root.join("db/seeds/images", filename)
  next if !File.exist?(path) || record.store_image.attached?

  record.store_image.attach(
    io: File.open(path),
    filename: filename,
    content_type: Marcel::MimeType.for(name: filename)
  )
end

origin = Manufacturer.find_or_create_by!(name: "Origin Jumpworks") do |m|
  m.slug = "origin-jumpworks"
  m.code = "ORIG"
end

drake = Manufacturer.find_or_create_by!(name: "Drake Interplanetary") do |m|
  m.slug = "drake-interplanetary"
  m.code = "DRAK"
end

explorer_600i = Model.find_or_create_by!(name: "600i Explorer") do |model|
  model.manufacturer = origin
  model.classification = "exploration"
  model.production_status = "flight-ready"
  model.size = "large"
end

dragonfly_black = Model.find_or_create_by!(name: "Dragonfly Black") do |model|
  model.manufacturer = drake
  model.classification = "competition"
  model.production_status = "flight-ready"
  model.size = "vehicle"
end

Model.find_or_create_by!(name: "600i Executive-Edition") do |model|
  model.manufacturer = origin
  model.rsi_name = "600i Executive Edition"
  model.classification = "exploration"
  model.production_status = "flight-ready"
  model.size = "large"
  model.base_model_id = explorer_600i.id
end

dragonfly_starkitten = Model.find_or_create_by!(name: "Dragonfly Starkitten Edition") do |model|
  model.manufacturer = drake
  model.rsi_name = "Dragonfly Star Kitten Edition"
  model.classification = "competition"
  model.production_status = "flight-ready"
  model.size = "vehicle"
  model.base_model_id = dragonfly_black.id
end

# Roustabout ("CitizenCon 2953 Dragonfly Paint") ships bundled inside the CitizenCon 2953
# Digital Goodies Pack, so it never appears as a standalone skin in hangar syncs and can't be
# picked up by the PaintsImporter. Ensure the paint exists on every Dragonfly variant and is
# shown once it has a store image. Drop a render at db/seeds/images/dragonfly-roustabout.* to
# attach one on environments that don't already have it.
roustabout_image = Dir[Rails.root.join("db/seeds/images/dragonfly-roustabout.*")].first
dragonfly_models = [dragonfly_black, dragonfly_starkitten, Model.find_by(name: "Dragonfly Yellowjacket")].compact
dragonfly_models.each do |dragonfly|
  paint = ModelPaint.find_or_create_by!(model_id: dragonfly.id, name: "Roustabout") do |model_paint|
    model_paint.active = true
    model_paint.hidden = true
  end

  if roustabout_image.present? && !paint.store_image.attached?
    paint.store_image.attach(
      io: File.open(roustabout_image),
      filename: File.basename(roustabout_image),
      content_type: Marcel::MimeType.for(name: File.basename(roustabout_image))
    )
  end

  paint.update!(hidden: false) if paint.hidden? && paint.store_image.attached?
end

aegis = Manufacturer.find_or_create_by!(code: "AEGS") do |m|
  m.name = "Aegis Dynamics"
  m.slug = "aegis-dynamics"
end

gladius = Model.find_by(name: "Gladius")

dunlevy = Model.find_or_create_by!(name: "Gladius Dunlevy") do |model|
  model.manufacturer = aegis
  model.rsi_name = "Aegis Gladius Dunlevy"
  model.sc_key = "aegs_gladius_dunlevy"
  model.classification = "combat"
  model.production_status = "flight-ready"
  model.size = "small"
  model.hidden = false
end
# Backfill outside the create-only block so the link is set once Gladius exists, even if
# Dunlevy was first seeded before the RSI importer created the base model.
dunlevy.update!(base_model_id: gladius.id) if gladius && dunlevy.base_model_id.blank?
attach_store_image.call(dunlevy, "gladius-dunlevy.jpg")

misc = Manufacturer.find_or_create_by!(name: "Musashi Industrial & Starflight Concern") do |m|
  m.slug = "musashi-industrial-starflight-concern"
  m.code = "MISC"
end

raptor = Model.find_or_create_by!(name: "Raptor") do |model|
  model.manufacturer = misc
end
attach_store_image.call(raptor, "raptor.jpg")
raptor.update!(hidden: false) if raptor.hidden?
