# frozen_string_literal: true

json.array! @loaners, partial: 'api/v1/models/minimal', as: :model
