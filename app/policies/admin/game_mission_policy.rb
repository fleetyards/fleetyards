module Admin
  class GameMissionPolicy < BasePolicy
    private def resource_access
      [:missions]
    end
  end
end
