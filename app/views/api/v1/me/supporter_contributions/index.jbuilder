# frozen_string_literal: true

json.array! @contributions, partial: "api/v1/me/supporter_contributions/supporter_contribution",
  as: :supporter_contribution
