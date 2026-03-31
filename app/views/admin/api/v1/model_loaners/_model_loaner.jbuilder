# frozen_string_literal: true

json.cache! ["v1", model_loaner] do
  json.partial!("admin/api/v1/model_loaners/base", model_loaner:)
end
