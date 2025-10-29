module Admin
  class OauthApplicationPolicy < BasePolicy
    private def resource_access
      [:oauth_applications]
    end
  end
end
