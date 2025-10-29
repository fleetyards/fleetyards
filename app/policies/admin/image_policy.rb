module Admin
  class ImagePolicy < BasePolicy
    private def resource_access
      [:images]
    end
  end
end
