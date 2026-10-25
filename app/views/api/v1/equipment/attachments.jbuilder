# frozen_string_literal: true

json.array! @attachments do |(fit, default)|
  json.port_type fit.port_type
  json.default default
  json.attachment do
    json.partial! "api/v1/equipment/equipment", equipment: fit.attachment
  end
end
