# frozen_string_literal: true

json.cache! ["v1", loaners_import] do
  json.partial!("api/v1/imports/base", import: loaners_import)
end
