module Admin
  class GameEventPolicy < BasePolicy
    private def resource_access
      [:game_events]
    end
  end
end
