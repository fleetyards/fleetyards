module Admin
  class ImportPolicy < BasePolicy
    private def resource_access
      [:imports]
    end
  end
end
