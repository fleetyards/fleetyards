module Admin
  class VideoPolicy < BasePolicy
    private def resource_access
      [:videos]
    end
  end
end
