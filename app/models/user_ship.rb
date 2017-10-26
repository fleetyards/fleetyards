# frozen_string_literal: true

class UserShip < ApplicationRecord
  paginates_per 30

  belongs_to :ship
  belongs_to :user

  alias_attribute :model, :ship

  validates :ship_id, presence: true

  NULL_ATTRS = %w[name].freeze
  before_save :nil_if_blank
  after_save :broadcast_update
  after_destroy :broadcast_update

  def broadcast_update
    ActionCable.server.broadcast("hangar_#{user.username}", to_builder.target!)
  end

  def self.purchased
    where(purchased: true)
  end

  def to_builder
    Jbuilder.new do |user_ship|
      user_ship.id id
      user_ship.name name
      user_ship.model do
        user_ship.name model.name
        user_ship.slug model.slug
      end
      user_ship.deleted user_ship.destroyed?
    end
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
