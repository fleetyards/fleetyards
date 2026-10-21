class HangarPolicy < ApplicationPolicy
  alias_rule :destroy?, :update?, :export?, :items?, :index?, to: :show?

  def show?
    user.present?
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end
