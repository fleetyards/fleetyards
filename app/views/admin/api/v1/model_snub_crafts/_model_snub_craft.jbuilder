# frozen_string_literal: true

json.cache! ["v1", model_snub_craft] do
  json.partial!("admin/api/v1/model_snub_crafts/base", model_snub_craft:)
end
