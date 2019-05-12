# frozen_string_literal: true

class Vehicle < ApplicationRecord
  paginates_per 30

  belongs_to :model
  belongs_to :user

  has_many :task_forces, dependent: :destroy
  has_many :hangar_groups, through: :task_forces

  has_many :vehicle_modules, dependent: :destroy
  has_many :model_modules, through: :vehicle_modules

  has_many :vehicle_upgrades, dependent: :destroy
  has_many :model_upgrades, through: :vehicle_upgrades

  validates :model_id, presence: true

  NULL_ATTRS = %w[name].freeze
  before_save :nil_if_blank
  after_save :set_flagship
  after_commit :broadcast_update

  ransack_alias :name, :name_or_model_name_or_model_slug
  ransack_alias :on_sale, :model_on_sale
  ransack_alias :manufacturer, :model_manufacturer_slug
  ransack_alias :classification, :model_classification
  ransack_alias :focus, :model_focus
  ransack_alias :size, :model_size
  ransack_alias :production_status, :model_production_status
  ransack_alias :hangar_groups, :hangar_groups_slug

  def broadcast_update
    ActionCable.server.broadcast("hangar_#{user.username}", to_json)
  end

  def self.purchased
    where(purchased: true)
  end

  def self.public
    purchased.where(purchased: true, public: true)
  end

  def set_flagship
    return unless flagship?

    # rubocop:disable SkipsModelValidations
    Vehicle.where(user_id: user_id, flagship: true)
           .where.not(id: id)
           .update_all(flagship: false)
    # rubocop:enable SkipsModelValidations
  end

  def to_json(*_args)
    to_jbuilder_json
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
