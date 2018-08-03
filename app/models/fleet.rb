# frozen_string_literal: true

require 'rsi_orgs_loader'

class Fleet < ApplicationRecord
  has_many :members,
           class_name: 'FleetMembership',
           dependent: :destroy,
           inverse_of: :fleet
  has_many :users, through: :members
  has_many :purchased_models,
           through: :users

  alias_attribute :models, :purchased_models

  validates :sid, presence: true, uniqueness: true

  before_create :fetch_rsi_org
  after_create :fetch_members

  def fetch_rsi_org
    org = RsiOrgsLoader.new.fetch(sid.downcase)
    return if org.blank?
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

  def fetch_members
    FleetMembersWorker.perform_async(id)
  end

  def add_members(rsi_members)
    rsi_member_ids = []
    rsi_members.each do |member|
      handle = member[:handle].strip.downcase
      membership = FleetMembership.where(fleet_id: id, handle: handle).first_or_create do |m|
        m.rank = member[:rank]
        m.avatar = member[:avatar]
      end
      membership.update(user_id: User.find_by(rsi_verified: true, rsi_handle: handle)&.id)
      rsi_member_ids << membership.id
    end
    FleetMembership.where(id: (member_ids - rsi_member_ids)).destroy_all
  end
end
