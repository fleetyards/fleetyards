class ImportPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user&.id == record.user_id
  end

  alias_rule :cancel?, to: :show?

  # Scoped by owner rather than by type: every subclass a user can own is
  # reached, and the system- and admin-owned ones carry no `user_id` at all, so
  # they are excluded without naming them.
  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end
