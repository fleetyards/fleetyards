# frozen_string_literal: true

class UserShip < ApplicationRecord
  paginates_per 30

  belongs_to :ship
  belongs_to :user

  validates :ship_id, presence: true

  NULL_ATTRS = %w[name].freeze
  before_save :nil_if_blank
  after_save :broadcast_save
  after_destroy :broadcast_destroy

  def broadcast_save
    ActionCable.server.broadcast("hangar_save_#{user.username}", to_builder.target!)
  end

  def broadcast_destroy
    ActionCable.server.broadcast("hangar_destroy_#{user.username}", to_builder.target!)
  end

  def self.purchased
    where(purchased: true)
  end

  def to_builder
    Jbuilder.new do |user_ship|
      user_ship.id id
      user_ship.name name
      user_ship.vehicle ship.to_builder.target!
      user_ship.deleted user_ship.destroyed?
    end
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
