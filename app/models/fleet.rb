# frozen_string_literal: true

require 'rsi_orgs_loader'

class Fleet < ApplicationRecord
  paginates_per 30

  validates :sid, presence: true, uniqueness: true

  before_create :fetch_rsi_org
  before_validation :transform_sid

  def transform_sid
    self.sid = sid.upcase
  end

  def fetch_rsi_org
    success, org = RsiOrgsLoader.new.fetch(sid.downcase)
    return unless success

    self.name = org.name
    self.logo = org.logo
    self.banner = org.banner
    self.background = org.background
    self.archetype = org.archetype
    self.main_activity = org.main_activity
    self.secondary_activity = org.secondary_activity
    self.recruiting = org.recruiting
    self.commitment = org.commitment
    self.rpg = org.rpg
    self.exclusive = org.exclusive
    self.member_count = org.member_count
  end
end
