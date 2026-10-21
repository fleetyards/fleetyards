module Admin
  class HomepageSettingPolicy < BasePolicy
    private def resource_access
      [:homepage]
    end
  end
end
