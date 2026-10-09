class BuybackPledgePolicy < ApplicationPolicy
  alias_rule :sync?, :sync_details?, :insurance_terms?, :destroy?, to: :index?

  def index?
    user.present?
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end
