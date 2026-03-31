# frozen_string_literal: true

module Admin
  class RsiRequestLogPolicy < BasePolicy
    private def resource_access
      [:"rsi-api-status"]
    end
  end
end
