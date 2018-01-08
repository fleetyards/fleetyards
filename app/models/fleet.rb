# frozen_string_literal: true

require 'rsi_orgs_loader'

class Fleet < ApplicationRecord
  has_many :members,
           -> { where(approved: true) },
           class_name: 'FleetMembership',
           dependent: :destroy,
           inverse_of: :fleet
  has_many :pending_members,
           -> { where(approved: false) },
           class_name: 'FleetMembership',
           dependent: :destroy,
           inverse_of: :fleet
  has_many :users, through: :members
  has_many :purchased_models,
           through: :users

  alias_attribute :models, :purchased_models

  validates :sid, presence: true, uniqueness: true

  before_create :fetch_rsi_org

  def fetch_rsi_org
    org = RsiOrgsLoader.new.fetch(sid.downcase)
    self.name = org.name
    self.logo = org.logo
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
