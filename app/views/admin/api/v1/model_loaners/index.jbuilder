# frozen_string_literal: true

json.items do
  json.array! @model_loaners, partial: "admin/api/v1/model_loaners/model_loaner", as: :model_loaner
end

json.partial! "api/shared/meta", result: @model_loaners
