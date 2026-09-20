# frozen_string_literal: true

json.cache! ["v1", dock_addition] do
  json.partial!("admin/api/v1/dock_additions/base", dock_addition:)
end
