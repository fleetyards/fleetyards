module Admin
  class AnnouncementPolicy < BasePolicy
    private def resource_access
      [:announcements]
    end
  end
end
