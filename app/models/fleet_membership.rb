# frozen_string_literal: true

class FleetMembership < ApplicationRecord
  belongs_to :fleet
  belongs_to :user

  enum role: { admin: 0, officer: 1, member: 2 }
  ransacker :role, formatter: proc { |v| FleetMembership.roles[v] } do |parent|
    parent.table[:role]
  end

  ransack_alias :username, :user_username

  after_create :notify_user

  def notify_user
    FleetMembershipMailer.new_invite(user.email, fleet).deliver_later
  end

  def invitation
    accepted_at.blank? && declined_at.blank?
  end

  def promote
    return if role == :admin

    if role == :officer
      update(role: :admin)
    else
      update(role: :officer)
    end
  end

  def demote
    return if role == :member

    if role == :admin
      update(role: :officer)
    else
      update(role: :member)
    end
  end
end
