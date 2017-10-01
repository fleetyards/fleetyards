# frozen_string_literal: true

class UserShip < ApplicationRecord
  paginates_per 30

  belongs_to :ship
  belongs_to :user

  validates :ship_id, presence: true

  NULL_ATTRS = %w[name].freeze
  before_save :nil_if_blank

  def self.purchased
    where(purchased: true)
  end

  def to_builder
    Jbuilder.new do |user_ship|
      user_ship.id id
      user_ship.name name
      user_ship.purchased purchased
      user_ship.ship ship.to_builder.target!
      user_ship.deleted user_ship.destroyed?
      user_ship.created_at created_at
      user_ship.updated_at updated_at
    end
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
