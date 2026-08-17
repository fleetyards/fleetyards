# frozen_string_literal: true

json.cache! ["v1", supporter_contribution] do
  json.partial!("admin/api/v1/supporter_contributions/base", supporter_contribution:)
end
