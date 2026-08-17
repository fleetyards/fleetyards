# frozen_string_literal: true

json.items do
  json.array! @supporter_contributions, partial: "admin/api/v1/supporter_contributions/supporter_contribution", as: :supporter_contribution
end
json.partial! "api/shared/meta", result: @supporter_contributions
