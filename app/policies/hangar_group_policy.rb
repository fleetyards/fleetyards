class HangarGroupPolicy < ApplicationPolicy
  alias_rule :create?, :destroy?, to: :update?

  def index?
    user.present?
  end

  def update?
    user&.id == record.user_id
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end
