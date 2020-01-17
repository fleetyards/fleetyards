# frozen_string_literal: true

class FleetMembership < ApplicationRecord
  belongs_to :fleet, touch: true
  belongs_to :user

  enum role: { admin: 0, officer: 1, member: 2 }
  ransacker :role, formatter: proc { |v| FleetMembership.roles[v] } do |parent|
    parent.table[:role]
  end

  ransack_alias :username, :user_username

  after_create :notify_user
  after_save :set_primary

  def set_primary
    return unless primary?

    # rubocop:disable SkipsModelValidations
    FleetMembership.where(user_id: user_id, primary: true)
                   .where.not(id: id)
                   .update_all(primary: false)
    # rubocop:enable SkipsModelValidations
  end

  def notify_user
    return unless invitation

    FleetMembershipMailer.new_invite(user.email, fleet).deliver_later
  end

  def invitation
    accepted_at.blank? && declined_at.blank?
  end

  def promote
    return if admin?

    if officer?
      update(role: :admin)
    else
      update(role: :officer)
    end
  end

  def demote
    return if member?

    if admin?
      update(role: :officer)
    else
      update(role: :member)
    end
  end
end
