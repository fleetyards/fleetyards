# frozen_string_literal: true

class FleetMembership < ApplicationRecord
  belongs_to :user
  belongs_to :fleet

  def approve
    self.approved = true
    save
  end

  def promote
    self.admin = true
    save
  end

  def demote
    self.admin = false
    save
  end
end
