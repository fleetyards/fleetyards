class HangarPledgeItemPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end
