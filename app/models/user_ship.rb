# frozen_string_literal: true

class UserShip < ApplicationRecord
  belongs_to :ship
  belongs_to :user

  validates :ship_id, presence: true

  NULL_ATTRS = %w[name].freeze
  before_save :nil_if_blank

  def self.purchased
    where(purchased: true)
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
