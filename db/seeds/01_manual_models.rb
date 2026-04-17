# frozen_string_literal: true

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
  model.sc_identifier = "orig_600i"
  model.classification = "exploration"
  model.production_status = "flight-ready"
  model.size = "large"
end

dragonfly_black = Model.find_or_create_by!(name: "Dragonfly Black") do |model|
  model.manufacturer = drake
  model.sc_identifier = "drak_dragonfly_black"
  model.classification = "competition"
  model.production_status = "flight-ready"
  model.size = "vehicle"
end

Model.find_or_create_by!(name: "600i Executive-Edition") do |model|
  model.manufacturer = origin
  model.rsi_name = "600i Executive Edition"
  model.sc_identifier = "orig_600i_executive_edition"
  model.classification = "exploration"
  model.production_status = "flight-ready"
  model.size = "large"
  model.base_model_id = explorer_600i.id
end

Model.find_or_create_by!(name: "Dragonfly Starkitten Edition") do |model|
  model.manufacturer = drake
  model.rsi_name = "Dragonfly Star Kitten Edition"
  model.sc_identifier = "drak_dragonfly"
  model.classification = "competition"
  model.production_status = "flight-ready"
  model.size = "vehicle"
  model.base_model_id = dragonfly_black.id
end

misc = Manufacturer.find_or_create_by!(name: "Musashi Industrial & Starflight Concern") do |m|
  m.slug = "musashi-industrial-starflight-concern"
  m.code = "MISC"
end

Model.find_or_create_by!(name: "Raptor") do |model|
  model.manufacturer = misc
  model.hidden = true
end
