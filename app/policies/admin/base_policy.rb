module Admin
  class BasePolicy < ApplicationPolicy
    default_rule :manage?

    alias_rule :index?, :show?, :create?, to: :manage?

    def manage?
      user.has_access?(resource_access)
    end

    relation_scope do |relation|
      if user.has_access?(resource_access)
        relation
      else
        relation.none
      end
    end

    private def resource_access
      raise NotImplementedError
    end
  end
end
