class BuybackPledgePolicy < ApplicationPolicy
  alias_rule :sync?, :sync_details?, to: :index?

  def index?
    user.present?
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end
