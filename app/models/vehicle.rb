# frozen_string_literal: true

class Vehicle < ApplicationRecord
  belongs_to :model
  belongs_to :user

  validates :model_id, presence: true

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
    Jbuilder.new do |vehicle|
      vehicle.id id
      vehicle.name name
      vehicle.deleted destroyed?
      vehicle.model do
        vehicle.name model.name
        vehicle.slug model.slug
      end
    end
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
