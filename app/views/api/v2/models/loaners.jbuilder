# frozen_string_literal: true

json.array! @loaners, partial: "api/v2/models/minimal", as: :model
