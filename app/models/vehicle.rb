# frozen_string_literal: true

class Vehicle < ApplicationRecord
  paginates_per 30

  belongs_to :model
  belongs_to :user

  has_many :task_forces, dependent: :destroy
  has_many :hangar_groups, through: :task_forces

  validates :model_id, presence: true

  NULL_ATTRS = %w[name].freeze
  before_save :nil_if_blank
  after_save :set_flagship
  after_commit :broadcast_update

  def broadcast_update
    ActionCable.server.broadcast("hangar_#{user.username}", to_builder.target!)
  end

  def self.purchased
    where(purchased: true)
  end

  def set_flagship
    return unless flagship?

    # rubocop:disable SkipsModelValidations
    Vehicle.where(user_id: user_id, flagship: true)
           .where.not(id: id)
           .update_all(flagship: false)
    # rubocop:enable SkipsModelValidations
  end

  def to_builder
    Jbuilder.new do |vehicle|
      vehicle.id id
      vehicle.name name
      vehicle.purchased purchased
      vehicle.flagship flagship
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
